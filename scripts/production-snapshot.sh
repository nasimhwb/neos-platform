#!/usr/bin/env bash
# ==============================================================================
# NEOS PRODUCTION SYSTEM READ-ONLY SNAPSHOT UTILITY
# ==============================================================================
# STRICT SAFETY GUARANTEE:
# This script is strictly READ-ONLY. It collects point-in-time system state,
# container metrics, network configurations, volume inventories, and routing
# tables without modifying any live production data or restarting services.
# Sensitive secrets (JWT secrets, passwords, service keys) are REDACTED.
# ==============================================================================
set -e
set -o pipefail

SNAPSHOT_ROOT="/srv/neos/production-snapshots"
TIMESTAMP=$(date -u +"%Y%m%d_%H%M%SZ")
SNAPSHOT_DIR="$SNAPSHOT_ROOT/snapshot_$TIMESTAMP"

echo "=========================================================================="
echo "=== NEOS PRODUCTION READ-ONLY STATE SNAPSHOT ENGINE"
echo "=========================================================================="
echo "Snapshot Time : $TIMESTAMP"
echo "Snapshot Dest : $SNAPSHOT_DIR"

mkdir -p "$SNAPSHOT_DIR"

# 1. System Host Information
echo "[1/10] Capturing host system state..."
{
    echo "=== Host Information ==="
    echo "Hostname: $(hostname)"
    echo "Kernel  : $(uname -a)"
    echo "Uptime  : $(uptime)"
    echo ""
    echo "=== Memory Usage ==="
    free -m || true
    echo ""
    echo "=== Disk Usage ==="
    df -h || true
    echo ""
    echo "=== CPU Load ==="
    cat /proc/loadavg || true
} > "$SNAPSHOT_DIR/host_system.txt" 2>&1

# 2. Docker Daemon & Engine Info
echo "[2/10] Capturing Docker engine metadata..."
{
    docker version || true
    echo ""
    docker info || true
} > "$SNAPSHOT_DIR/docker_info.txt" 2>&1

# 3. Docker Containers Lifecycle & Details
echo "[3/10] Capturing running container states..."
docker ps -a --no-trunc --format "table {{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}" > "$SNAPSHOT_DIR/docker_ps.txt" 2>&1

# Capture detailed inspect metadata for critical containers
mkdir -p "$SNAPSHOT_DIR/inspect"
CRITICAL_CONTAINERS=("neos_traefik" "neos_app" "neos_supabase_gateway" "neos_supabase_auth" "neos_supabase_rest" "neos_supabase_storage" "neos_postgres" "neos_pgbouncer" "neos_redis" "neos_minio")

for cname in "${CRITICAL_CONTAINERS[@]}"; do
    if docker ps -a --format '{{.Names}}' | grep -Eq "^${cname}$"; then
        # Redact common sensitive environment variable patterns
        docker inspect "$cname" | sed -E 's/(PASSWORD|SECRET|KEY|TOKEN)=[^"]+/\1=<REDACTED>/g' > "$SNAPSHOT_DIR/inspect/${cname}.json" 2>&1 || true
    fi
done

# 4. Docker Networks & Connected Containers
echo "[4/10] Capturing Docker network topologies..."
{
    docker network ls --no-trunc
    echo ""
    for net in $(docker network ls --format '{{.Name}}'); do
        echo "=== Network: $net ==="
        docker network inspect "$net" | sed -E 's/(PASSWORD|SECRET|KEY|TOKEN)=[^"]+/\1=<REDACTED>/g' || true
        echo ""
    done
} > "$SNAPSHOT_DIR/docker_networks.txt" 2>&1

# 5. Docker Volumes Inventory
echo "[5/10] Capturing volume metadata..."
docker volume ls > "$SNAPSHOT_DIR/docker_volumes.txt" 2>&1

# 6. Configuration File Checksums
echo "[6/10] Generating configuration file checksums..."
{
    echo "=== SHA256 Checksums of Production Configurations ==="
    if [ -d "/srv/neos/neos-platform" ]; then
        find /srv/neos/neos-platform/configs /srv/neos/neos-platform/compose -type f 2>/dev/null | sort | while read -r f; do
            sha256sum "$f" || true
        done
    fi
} > "$SNAPSHOT_DIR/config_checksums.txt" 2>&1

# 7. PostgreSQL Database Catalog (Read-Only)
echo "[7/10] Capturing PostgreSQL database catalog..."
{
    if docker ps --format '{{.Names}}' | grep -q "neos_postgres"; then
        echo "=== PostgreSQL Databases ==="
        docker exec neos_postgres psql -U postgres -c "\l+" 2>/dev/null || echo "Unable to query \l+"
        echo ""
        echo "=== PostgreSQL Schemas in 'postgres' database ==="
        docker exec neos_postgres psql -U postgres -d postgres -c "\dn" 2>/dev/null || true
        echo ""
        echo "=== Public Tables & Views ==="
        docker exec neos_postgres psql -U postgres -d postgres -c "\dt+ public.*" 2>/dev/null || true
        docker exec neos_postgres psql -U postgres -d postgres -c "\dv+ public.*" 2>/dev/null || true
        echo ""
        echo "=== Storage Buckets & Counts ==="
        docker exec neos_postgres psql -U postgres -d postgres -c "SELECT id, name, public, created_at FROM storage.buckets;" 2>/dev/null || true
        docker exec neos_postgres psql -U postgres -d postgres -c "SELECT bucket_id, count(*) FROM storage.objects GROUP BY bucket_id;" 2>/dev/null || true
    else
        echo "Postgres container not running during snapshot."
    fi
} > "$SNAPSHOT_DIR/database_catalog.txt" 2>&1

# 8. Traefik Dynamic Configuration
echo "[8/10] Capturing Traefik routing configuration..."
{
    if [ -f "/srv/neos/neos-platform/configs/traefik/dynamic.yml" ]; then
        # Redact basic auth hashes
        sed -E 's/users:.*$/users: ["<REDACTED>"]/g' /srv/neos/neos-platform/configs/traefik/dynamic.yml
    elif [ -f "/srv/neos/current/configs/traefik/dynamic.yml" ]; then
        sed -E 's/users:.*$/users: ["<REDACTED>"]/g' /srv/neos/current/configs/traefik/dynamic.yml
    else
        echo "Traefik dynamic.yml not found."
    fi
} > "$SNAPSHOT_DIR/traefik_dynamic_routing.txt" 2>&1

# 9. Health & Public Endpoint Probes
echo "[9/10] Probing live health endpoints..."
{
    echo "=== /api/health (webapp.neosfacility.com) ==="
    curl -k -i -s -S -m 5 https://webapp.neosfacility.com/api/health 2>&1 || true
    echo ""
    echo "=== /api/health (test.neosfacility.com) ==="
    curl -k -i -s -S -m 5 https://test.neosfacility.com/api/health 2>&1 || true
    echo ""
    echo "=== Supabase Gateway In-Cluster Health ==="
    docker exec neos_supabase_gateway wget -qO- http://supabase-auth:9999/health 2>&1 || true
    echo ""
} > "$SNAPSHOT_DIR/health_endpoints_probe.txt" 2>&1

# 10. Generate Summary & Manifest
echo "[10/10] Writing snapshot manifest..."
cat <<MANIFEST > "$SNAPSHOT_DIR/MANIFEST.md"
# NEOS Production Snapshot Manifest

- **Snapshot ID:** \`snapshot_$TIMESTAMP\`
- **Captured At:** \`$(date -u +"%Y-%m-%dT%H:%M:%SZ")\`
- **Captured Files:**
  - \`host_system.txt\` (CPU, RAM, Disk utilization)
  - \`docker_info.txt\` (Docker daemon state)
  - \`docker_ps.txt\` (Container lifecycle states)
  - \`inspect/\` (Redacted container metadata)
  - \`docker_networks.txt\` (Network bridge topology)
  - \`docker_volumes.txt\` (Volume list)
  - \`config_checksums.txt\` (SHA256 file hashes)
  - \`database_catalog.txt\` (PostgreSQL databases, schemas, bucket counts)
  - \`traefik_dynamic_routing.txt\` (Traefik routing rules)
  - \`health_endpoints_probe.txt\` (Live probe responses)
MANIFEST

echo "=========================================================================="
echo "=== Snapshot $TIMESTAMP successfully saved to:"
echo "    $SNAPSHOT_DIR"
echo "=========================================================================="
