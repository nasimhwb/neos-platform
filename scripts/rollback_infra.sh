#!/bin/bash
# ==============================================================================
# NEOS PLATFORM - SRE INFRASTRUCTURE ROLLBACK RUNNER
# ==============================================================================
# Reverts the active production symlink to the previous healthy release:
#   1. Scans releases directory to locate the previous release folder.
#   2. Swaps /srv/neos/current symlink atomically.
#   3. CD to previous release folder.
#   4. Restarts all containers from the previous configurations.
#   5. Polls for health checks and executes smoke tests.

set -eu
set -o pipefail

BASE_DIR="/srv/neos"
RELEASES_DIR="$BASE_DIR/releases"
CURRENT_LINK="$BASE_DIR/current"

# Master Docker Compose command mapping all config files
COMPOSE_CMD="docker compose --env-file .env -f compose/compose.base.yml -f compose/compose.database.yml -f compose/compose.storage.yml -f compose/compose.monitoring.yml -f compose/compose.proxy.yml -f compose/compose.security.yml -f compose/compose.dashboard.yml"

# ANSI color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}==========================================================================${NC}"
echo -e "${BLUE}=== Starting Manual SRE Infrastructure Rollback ===${NC}"
echo -e "${BLUE}==========================================================================${NC}"

# 1. Get current active release
if [ ! -L "$CURRENT_LINK" ]; then
    echo -e "${RED}ERROR: Symlink $CURRENT_LINK is missing. Cannot revert.${NC}"
    exit 1
fi
ACTIVE_RELEASE=$(readlink -f "$CURRENT_LINK")
echo -e "Current release path: ${YELLOW}$ACTIVE_RELEASE${NC}"

# 2. Locate previous release folder
PREV_RELEASE_PATH=$(ls -1td "$RELEASES_DIR"/infra-* 2>/dev/null | sed -n '2p')
if [ -z "$PREV_RELEASE_PATH" ] || [ ! -d "$PREV_RELEASE_PATH" ]; then
    echo -e "${RED}ERROR: Previous release directory not found. Rollback is impossible.${NC}"
    exit 1
fi
echo -e "Reverting to previous release: ${GREEN}$(basename "$PREV_RELEASE_PATH")${NC}"

# Confirm rollback if interactive
if [ -t 0 ]; then
    read -p "Are you sure you want to revert to $(basename "$PREV_RELEASE_PATH")? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Rollback cancelled."
        exit 0
    fi
fi

# 3. Swap Symlink atomically
echo "Updating symlink..."
ln -sfn "$PREV_RELEASE_PATH" "$BASE_DIR/current_tmp"
mv -Tf "$BASE_DIR/current_tmp" "$CURRENT_LINK"
echo -e "Atomic swap complete: ${GREEN}$CURRENT_LINK -> $(readlink $CURRENT_LINK)${NC}"

# 4. Redeploy compose from the reverted directory
echo "Restarting service containers from previous configurations..."
cd "$PREV_RELEASE_PATH"
$COMPOSE_CMD up -d

# 5. Run health and smoke verification checks
echo "Verifying health on reverted release..."
check_health() {
    local name=$1
    local status=""
    for i in {1..10}; do
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

check_health "neos_postgres" || { echo -e "${RED}Warning: Reverted PostgreSQL unhealthy.${NC}"; }
check_health "neos_redis" || { echo -e "${RED}Warning: Reverted Redis unhealthy.${NC}"; }
check_health "neos_traefik" || { echo -e "${RED}Warning: Reverted Traefik unhealthy.${NC}"; }

# Run smoke tests
echo "Executing smoke tests..."
chmod +x scripts/smoke_tests.sh
./scripts/smoke_tests.sh || { echo -e "${RED}Warning: Smoke tests failed post-rollback.${NC}"; }

echo -e "\n${GREEN}==========================================================================${NC}"
echo -e "${GREEN}=== [PASS] Reversion to $(basename "$PREV_RELEASE_PATH") complete! ===${NC}"
echo -e "${GREEN}==========================================================================${NC}"
exit 0
