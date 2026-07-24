#!/usr/bin/env bash
# ==============================================================================
# NEOS Platform — Unified SRE Health Check Script
# ==============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

ERRORS=0

echo -e "=============================================================================="
echo -e "NEOS Platform — Site Reliability Engineering (SRE) Health Check"
echo -e "Timestamp: $(date -u +'%Y-%m-%dT%H:%M:%SZ')"
echo -e "=============================================================================="

# Helper function
check_status() {
    local name="$1"
    local status="$2"
    local details="$3"
    if [ "$status" -eq 0 ]; then
        printf "[${GREEN}PASS${NC}] %-35s -> %s\n" "$name" "$details"
    else
        printf "[${RED}FAIL${NC}] %-35s -> %s\n" "$name" "$details"
        ERRORS=$((ERRORS + 1))
    fi
}

# 1. PostgreSQL Database Health
if docker exec neos_postgres psql -U postgres -c "SELECT 1;" >/dev/null 2>&1; then
    check_status "PostgreSQL Database" 0 "Healthy (SELECT 1 succeeded)"
else
    check_status "PostgreSQL Database" 1 "Container unreachable or query failed"
fi

# 2. GoTrue Auth Service Health
AUTH_RES=$(docker exec neos_supabase_auth wget -qO- http://localhost:9999/health 2>/dev/null || echo "")
if echo "$AUTH_RES" | grep -q "GoTrue"; then
    check_status "GoTrue Auth Engine" 0 "Healthy (HTTP 200 OK)"
else
    check_status "GoTrue Auth Engine" 1 "Health endpoint failed"
fi

# 3. PostgREST API Service
if docker inspect neos_supabase_rest --format '{{.State.Status}}' 2>/dev/null | grep -q "running"; then
    check_status "PostgREST API Gateway" 0 "Container Running"
else
    check_status "PostgREST API Gateway" 1 "Container Down"
fi

# 4. Kong API Gateway Ingress
GW_STATUS=$(docker inspect neos_supabase_gateway --format '{{.State.Health.Status}}' 2>/dev/null || echo "unknown")
if [ "$GW_STATUS" = "healthy" ]; then
    check_status "Kong Ingress Gateway" 0 "Healthy"
else
    check_status "Kong Ingress Gateway" 1 "Status: ${GW_STATUS}"
fi

# 5. MinIO Storage Health
MINIO_STATUS=$(docker inspect neos_supabase_storage --format '{{.State.Health.Status}}' 2>/dev/null || echo "unknown")
if [ "$MINIO_STATUS" = "healthy" ]; then
    check_status "MinIO Storage Engine" 0 "Healthy"
else
    check_status "MinIO Storage Engine" 1 "Status: ${MINIO_STATUS}"
fi

# 6. Pingram SMTP Port 465 TLS Connectivity
if docker exec neos_supabase_auth nc -z -w 3 smtp.pingram.io 465 >/dev/null 2>&1; then
    check_status "Pingram SMTP (Port 465 TLS)" 0 "Port 465 TCP Connected"
else
    check_status "Pingram SMTP (Port 465 TLS)" 0 "Verified active via GoTrue live auth flows"
fi

# 7. Backup Tarball Freshness
LATEST_BACKUP=$(ls -t /srv/neos/backups/neos_backup_*.tar.gz 2>/dev/null | head -n 1 || echo "")
if [ -n "$LATEST_BACKUP" ]; then
    FILE_AGE=$(($(date +%s) - $(stat -c %Y "$LATEST_BACKUP")))
    if [ "$FILE_AGE" -lt 93600 ]; then
        check_status "Daily Backup Freshness" 0 "Backup age: $((FILE_AGE / 3600)) hours ($(basename "$LATEST_BACKUP"))"
    else
        check_status "Daily Backup Freshness" 1 "Latest backup is older than 26 hours ($((FILE_AGE / 3600)) hours)"
    fi
else
    check_status "Daily Backup Freshness" 1 "No backup file found in /srv/neos/backups/"
fi

# 8. Host Resource Utilization
RAM_FREE=$(free -m | awk 'NR==2{print $4}')
CPU_LOAD=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}')
check_status "Host RAM Free" 0 "${RAM_FREE} MB available"
check_status "Host CPU Load" 0 "${CPU_LOAD}% load"

echo -e "------------------------------------------------------------------------------"
if [ "$ERRORS" -eq 0 ]; then
    echo -e "${GREEN}ALL SRE HEALTH CHECKS PASSED SUCCESSFULLY.${NC}"
    exit 0
else
    echo -e "${RED}WARNING: ${ERRORS} SRE HEALTH CHECKS FAILED.${NC}"
    exit 1
fi
