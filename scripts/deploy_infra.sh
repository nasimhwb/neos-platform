#!/bin/bash
# ==============================================================================
# NEOS PLATFORM - SRE INFRASTRUCTURE DEPLOYMENT ENGINE
# ==============================================================================
# Sequenced production deployment orchestrator:
#   1. Runs pre-flight checks to prepare the VPS.
#   2. Provisions versioned release directory.
#   3. Links shared production .env file.
#   4. Checks compose configuration syntax.
#   5. Launches service stacks in strict dependency order.
#   6. Polls and waits for SRE healthchecks.
#   7. Runs smoke tests suite.
#   8. Executes logical backup & recovery validation.
#   9. Atomically swaps /srv/neos/current symlink on success.
#   10. Generates release notes and deployment reports.
#   11. Triggers automatic rollback to previous release on failure.

set -eu
set -o pipefail

BASE_DIR="/srv/neos"
RELEASES_DIR="$BASE_DIR/releases"
SHARED_DIR="$BASE_DIR/shared"
CURRENT_LINK="$BASE_DIR/current"
TMP_SRC="/srv/neos/tmp/deploy-src"

# Master Docker Compose command mapping all config files
COMPOSE_CMD="docker compose --env-file .env -f compose/compose.base.yml -f compose/compose.database.yml -f compose/compose.storage.yml -f compose/compose.monitoring.yml -f compose/compose.proxy.yml -f compose/compose.security.yml -f compose/compose.dashboard.yml"

# ANSI color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}==========================================================================${NC}"
echo -e "${BLUE}=== Starting Production Infrastructure Deployment ===${NC}"
echo -e "${BLUE}==========================================================================${NC}"

# 1. VPS Readiness Check (Pre-flight checks)
echo "1. Performing system pre-flight verification checks..."
chmod +x bootstrap/verify.sh
./bootstrap/verify.sh --pre || { echo -e "${RED}Pre-flight verification failed. Aborting deployment.${NC}"; exit 1; }

# 2. Setup Versioned Release
RELEASE_ID="infra-$(date +"%Y%m%d_%H%M%S")"
NEW_RELEASE_PATH="$RELEASES_DIR/$RELEASE_ID"
echo -e "Release ID  : ${GREEN}$RELEASE_ID${NC}"
echo -e "Target Path : ${GREEN}$NEW_RELEASE_PATH${NC}"

# Ensure directories exist
mkdir -p "$RELEASES_DIR"
mkdir -p "$SHARED_DIR"

# Resolve deployment source code
SRC_PATH=""
if [ -d "$TMP_SRC" ]; then
    SRC_PATH="$TMP_SRC"
else
    # Fallback to current project root directory for dry-run
    SRC_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fi

echo "Copying source artifacts to release directory..."
mkdir -p "$NEW_RELEASE_PATH"
cp -R "$SRC_PATH"/. "$NEW_RELEASE_PATH"/

# Link Shared environment configurations
if [ -f "$SHARED_DIR/.env" ]; then
    echo "Linking shared .env configuration..."
    ln -sf "$SHARED_DIR/.env" "$NEW_RELEASE_PATH/.env"
else
    echo -e "${YELLOW}Warning: Shared .env not found at $SHARED_DIR/.env. Utilizing local template.${NC}"
    if [ -f "$NEW_RELEASE_PATH/.env" ]; then
        echo "Using existing .env in release."
    else
        cp "$NEW_RELEASE_PATH/.env.example" "$NEW_RELEASE_PATH/.env"
    fi
fi

# CD to release directory for execution
cd "$NEW_RELEASE_PATH"

# 3. Check Compose Syntax
echo "2. Validating docker compose configuration syntax..."
make config-check || { echo -e "${RED}Docker Compose configuration syntax is invalid.${NC}"; exit 1; }

# Track active color or state for rollback purposes
PREV_RELEASE=""
if [ -L "$CURRENT_LINK" ]; then
    PREV_RELEASE=$(readlink -f "$CURRENT_LINK")
fi

rollback_deployment() {
    echo -e "\n${RED}==========================================================================${NC}"
    echo -e "${RED}>>> DEPLOYMENT VALIDATION FAILED! STARTING SAFE AUTOMATIC ROLLBACK... <<<${NC}"
    echo -e "${RED}==========================================================================${NC}"
    
    # CD to project root directory
    cd "$SRC_PATH"

    # Stop failed services in new release folder
    echo "Stopping failed containers..."
    cd "$NEW_RELEASE_PATH"
    $COMPOSE_CMD down --remove-orphans || true
    
    # Remove failed release folder to prevent garbage pollution
    rm -rf "$NEW_RELEASE_PATH"
    
    if [ -n "$PREV_RELEASE" ] && [ -d "$PREV_RELEASE" ]; then
        echo -e "Reverting to previous healthy release: ${GREEN}$(basename "$PREV_RELEASE")${NC}"
        ln -sfn "$PREV_RELEASE" "$BASE_DIR/current_tmp"
        mv -Tf "$BASE_DIR/current_tmp" "$CURRENT_LINK"
        
        # Restart previous compose services
        cd "$PREV_RELEASE"
        $COMPOSE_CMD up -d || true
        echo -e "${GREEN}Rollback finished. Production traffic remains on reverted release.${NC}"
    else
        echo -e "${YELLOW}No previous release available. Services torn down.${NC}"
    fi
    exit 1
}

# 4. Sequenced Deployment Startup
echo "3. Starting services in strict dependency order..."

# Phase 1: Base Networks and Volume structures
echo "  [Phase 1] Initializing networks and volumes..."
# Networks and volumes are automatically created by docker compose during Phase 2.

# Phase 2: Databases, Cache, and Storage
echo "  [Phase 2] Launching PostgreSQL, PgBouncer, Redis, and MinIO..."
$COMPOSE_CMD up -d db pgbouncer cache redis-exporter postgres-exporter object-store minio-init

# Phase 3: Wait for databases and storage to boot (Healthcheck loop)
echo "  [Phase 3] Waiting for databases and storage health check..."
check_health() {
    local name=$1
    local status=""
    for i in {1..20}; do
        if ! docker ps -a --format '{{.Names}}' | grep -q "^${name}$"; then
            sleep 2
            continue
        fi
        status=$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' "$name" 2>/dev/null || echo "failed")
        if [ "$status" = "healthy" ] || [ "$status" = "running" ]; then
            return 0
        fi
        sleep 2
    done
    return 1
}

check_health "neos_postgres" || { echo "PostgreSQL healthcheck failed."; rollback_deployment; }
check_health "neos_redis" || { echo "Redis cache healthcheck failed."; rollback_deployment; }
check_health "neos_minio" || { echo "MinIO object storage healthcheck failed."; rollback_deployment; }

# Phase 4: Monitoring, Ingress Routing (Traefik), and Next.js Dashboard
echo "  [Phase 4] Launching Monitoring stack, Traefik proxy, and Next.js Dashboard..."
$COMPOSE_CMD up -d

# Phase 5: Wait for all health checks
echo "  [Phase 5] Waiting for remaining core services health checks..."
check_health "neos_traefik" || { echo "Traefik proxy healthcheck failed."; rollback_deployment; }
check_health "neos_dashboard" || { echo "Dashboard control center healthcheck failed."; rollback_deployment; }

# 5. Execute Smoke Tests
echo "4. Running automated smoke checks..."
chmod +x scripts/smoke_tests.sh
./scripts/smoke_tests.sh || { echo "Smoke test execution failed."; rollback_deployment; }

# 6. Execute Backup and Restore Validation
echo "5. Running logical backups and recovery validation checks..."
chmod +x scripts/validate_backups.sh
./scripts/validate_backups.sh || { echo "Backup and Recovery validation checks failed."; rollback_deployment; }

# 7. Atomic Swap on Success
echo "6. Performing atomic symlink swap..."
ln -sfn "$NEW_RELEASE_PATH" "$BASE_DIR/current_tmp"
mv -Tf "$BASE_DIR/current_tmp" "$CURRENT_LINK"
echo -e "Active symlink updated: ${GREEN}$CURRENT_LINK -> $(readlink $CURRENT_LINK)${NC}"

# 8. Release Notes Generation
echo "7. Generating release notes..."
cat <<EOF > "$NEW_RELEASE_PATH/release_notes.md"
# Release Notes — $RELEASE_ID
- **Release Version**: $RELEASE_ID
- **Timestamp**: $(date -uIs)
- **Git Commit**: $(git rev-parse HEAD 2>/dev/null || echo "Unknown")
- **Deployer**: $(whoami)

## Included Updates
- Staged all SRE Operations services.
- Initialized automated logical backups.
- Configured PostgreSQL 16, PgBouncer pooler, Redis, and MinIO Object Storage.
EOF

# 9. Deployment Report Generation
mkdir -p "/srv/neos/shared/reports"
REPORT_FILE="/srv/neos/shared/reports/deployment_report.md"
cat <<EOF > "$REPORT_FILE"
# Infrastructure Deployment Report

- **Release ID**: $RELEASE_ID
- **Git Hash**: $(git rev-parse HEAD 2>/dev/null || echo "N/A")
- **Timestamp**: $(date -uIs)
- **Status**: **SUCCESS**

## Deployment Checklists status
- [x] VPS Preparation (Pre-flight checks)
- [x] Sequenced service deployment
- [x] Healthcheck verification
- [x] Automated Smoke Tests execution
- [x] Backup & Restore validation run
- [x] Atomic symlink update
EOF

# Conditionally copy to local IDE brain directory if configured
if [ -n "${IDE_BRAIN_DIR:-}" ] && [ -d "$IDE_BRAIN_DIR" ]; then
    cp "$REPORT_FILE" "$IDE_BRAIN_DIR/deployment_report.md"
    echo "Deployment report saved to IDE artifacts: $IDE_BRAIN_DIR/deployment_report.md"
fi
echo "Deployment report saved to: $REPORT_FILE"

# 10. Prune obsolete releases (retain latest 5)
echo "8. Cleaning up obsolete release files (retaining latest 5)..."
cd "$RELEASES_DIR"
ls -1t | tail -n +6 | while read -r old_release; do
    if [ -n "$old_release" ]; then
        echo "Removing old release folder: $old_release"
        rm -rf "$old_release"
    fi
done

echo -e "\n${GREEN}==========================================================================${NC}"
echo -e "${GREEN}=== [PASS] Production Infrastructure Release $RELEASE_ID successfully active! ===${NC}"
echo -e "${GREEN}==========================================================================${NC}"
exit 0
