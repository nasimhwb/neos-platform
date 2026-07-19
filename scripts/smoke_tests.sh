#!/bin/bash
# ==============================================================================
# NEOS PLATFORM - AUTOMATED SMOKE TESTS
# ==============================================================================
# This script executes validation probes across all core components of the platform:
#   - Docker Daemon & Core Containers
#   - Ingress Router (Traefik)
#   - Administration (Portainer)
#   - Persistence (PostgreSQL, PgBouncer)
#   - Cache (Redis)
#   - Object Storage (MinIO)
#   - Dashboard & Backend APIs
#   - Monitoring Stack (Prometheus)

set -eo pipefail

# Load environment configuration if present
if [ -f "$(dirname "$0")/../.env" ]; then
    set -a
    source <(tr -d '\r' < "$(dirname "$0")/../.env")
    set +a
fi

# ANSI color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

FAILED_PROBES=0

echo -e "${BLUE}==========================================================================${NC}"
echo -e "${BLUE}=== RUNNING NEOS PLATFORM PRODUCTION SMOKE TESTS ===${NC}"
echo -e "${BLUE}==========================================================================${NC}"

# Helper to assert running container
check_container() {
    local name=$1
    echo -n "Checking container '$name' state... "
    if ! docker ps -a --format '{{.Names}}' | grep -Eq "^${name}$"; then
        echo -e "${RED}MISSING (Not Created)${NC}"
        FAILED_PROBES=$((FAILED_PROBES + 1))
        return 1
    fi
    local status
    status=$(docker inspect -f '{{.State.Status}}' "$name")
    if [ "$status" != "running" ]; then
        echo -e "${RED}FAIL (State: $status)${NC}"
        FAILED_PROBES=$((FAILED_PROBES + 1))
        return 1
    fi
    echo -e "${GREEN}PASS (Running)${NC}"
    return 0
}

# 1. Verify Docker Engine
echo -e "\n${BLUE}--- 1. Verifying Docker Engine ---${NC}"
if docker info &>/dev/null; then
    echo -e "${GREEN}[PASS] Docker Daemon is responsive.${NC}"
else
    echo -e "${RED}[FAIL] Docker Daemon is unreachable.${NC}"
    FAILED_PROBES=$((FAILED_PROBES + 1))
fi

# 2. Check Core Containers
echo -e "\n${BLUE}--- 2. Auditing Core Service Containers ---${NC}"
check_container "neos_traefik" || true
check_container "neos_portainer" || true
check_container "neos_postgres" || true
check_container "neos_pgbouncer" || true
check_container "neos_redis" || true
check_container "neos_minio" || true
check_container "neos_prometheus" || true
check_container "neos_grafana" || true
check_container "neos_dashboard" || true

# 3. Check Traefik Router
echo -e "\n${BLUE}--- 3. Verifying Ingress Router (Traefik) ---${NC}"
if curl -s -I http://localhost:80/ | head -n 1 | grep -q "HTTP"; then
    echo -e "${GREEN}[PASS] Traefik port 80 is accepting HTTP traffic.${NC}"
else
    echo -e "${RED}[FAIL] Traefik port 80 is unresponsive.${NC}"
    FAILED_PROBES=$((FAILED_PROBES + 1))
fi

# 4. Check Portainer
echo -e "\n${BLUE}--- 4. Verifying Portainer Admin Console ---${NC}"
if curl -s -I http://localhost:9000/ &>/dev/null || docker ps --filter "name=neos_portainer" --filter "status=running" --format '{{.Names}}' | grep -q "neos_portainer"; then
    echo -e "${GREEN}[PASS] Portainer console listener is healthy.${NC}"
else
    echo -e "${RED}[FAIL] Portainer console port is unresponsive.${NC}"
    FAILED_PROBES=$((FAILED_PROBES + 1))
fi

# 5. Check PostgreSQL
echo -e "\n${BLUE}--- 5. Verifying PostgreSQL ---${NC}"
if docker exec neos_postgres pg_isready -U postgres &>/dev/null; then
    echo -e "${GREEN}[PASS] PostgreSQL is ready and accepting queries.${NC}"
else
    echo -e "${RED}[FAIL] PostgreSQL is offline or unreachable.${NC}"
    FAILED_PROBES=$((FAILED_PROBES + 1))
fi

# 6. Check PgBouncer
echo -e "\n${BLUE}--- 6. Verifying PgBouncer Connection Pooler ---${NC}"
if (echo >/dev/tcp/127.0.0.1/6432) &>/dev/null; then
    echo -e "${GREEN}[PASS] PgBouncer listener responds on port 6432.${NC}"
else
    echo -e "${RED}[FAIL] PgBouncer is not listening on port 6432.${NC}"
    FAILED_PROBES=$((FAILED_PROBES + 1))
fi

# 7. Check Redis
echo -e "\n${BLUE}--- 7. Verifying Redis Cache ---${NC}"
if docker exec neos_redis redis-cli -a "${REDIS_PASSWORD}" ping 2>/dev/null | grep -q "PONG"; then
    echo -e "${GREEN}[PASS] Redis cache answers PING request.${NC}"
else
    echo -e "${RED}[FAIL] Redis cache did not answer PING.${NC}"
    FAILED_PROBES=$((FAILED_PROBES + 1))
fi

# 8. Check MinIO
echo -e "\n${BLUE}--- 8. Verifying MinIO Object Storage ---${NC}"
if docker exec neos_minio curl -s -f http://localhost:9000/minio/health/live &>/dev/null; then
    echo -e "${GREEN}[PASS] MinIO reports alive on S3 HTTP probe.${NC}"
else
    echo -e "${RED}[FAIL] MinIO live probe returned failure status.${NC}"
    FAILED_PROBES=$((FAILED_PROBES + 1))
fi

# 9. Check Dashboard & Platform APIs
echo -e "\n${BLUE}--- 9. Verifying Dashboard & Backend APIs ---${NC}"
if docker ps --filter "name=neos_dashboard" --filter "status=running" --format '{{.Names}}' | grep -q "neos_dashboard"; then
    echo -e "${GREEN}[PASS] Next.js Dashboard container is running.${NC}"
else
    echo -e "${RED}[FAIL] Next.js Dashboard container is down.${NC}"
    FAILED_PROBES=$((FAILED_PROBES + 1))
fi

# 10. Check Monitoring Stack
echo -e "\n${BLUE}--- 10. Verifying Prometheus Monitoring ---${NC}"
if docker ps --filter "name=neos_prometheus" --filter "status=running" --format '{{.Names}}' | grep -q "neos_prometheus"; then
    echo -e "${GREEN}[PASS] Prometheus monitoring is scraping metrics.${NC}"
else
    echo -e "${RED}[FAIL] Prometheus monitoring container is down.${NC}"
    FAILED_PROBES=$((FAILED_PROBES + 1))
fi

echo -e "\n${BLUE}==========================================================================${NC}"
if [ $FAILED_PROBES -eq 0 ]; then
    echo -e "${GREEN}=== [PASS] All Production Smoke Probes Completed Successfully! ===${NC}"
    echo -e "${BLUE}==========================================================================${NC}"
    exit 0
else
    echo -e "${RED}=== [FAIL] Smoke Tests Completed with $FAILED_PROBES Outages! ===${NC}"
    echo -e "${BLUE}==========================================================================${NC}"
    exit 1
fi
