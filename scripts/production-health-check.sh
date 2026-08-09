#!/usr/bin/env bash
# ==============================================================================
# NEOS PRODUCTION SYSTEM READ-ONLY HEALTH CHECK SCRIPT
# ==============================================================================
# STRICT SAFETY GUARANTEE:
# This script is strictly READ-ONLY. It never restarts services, recreates
# containers, modifies volumes, executes destructive queries, prunes Docker,
# alters configurations, or touches persistent data.
# ==============================================================================
set -o pipefail

# ANSI color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Counters
TOTAL_PASS=0
TOTAL_WARN=0
TOTAL_FAIL=0

record_result() {
    local status=$1
    if [ "$status" = "PASS" ]; then
        TOTAL_PASS=$((TOTAL_PASS + 1))
    elif [ "$status" = "WARN" ]; then
        TOTAL_WARN=$((TOTAL_WARN + 1))
    else
        TOTAL_FAIL=$((TOTAL_FAIL + 1))
    fi
}

echo -e "${BLUE}==========================================================================${NC}"
echo -e "${BOLD}${CYAN}         NEOS PRODUCTION READ-ONLY HEALTH CHECK & AUDIT SUITE             ${NC}"
echo -e "${BLUE}==========================================================================${NC}"
echo "Execution Time: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
echo "Target Node   : $(hostname -f 2>/dev/null || hostname)"
echo ""

# ------------------------------------------------------------------------------
# 1. Host Resources Check
# ------------------------------------------------------------------------------
echo -e "${BOLD}${BLUE}[1/8] Host System Resources${NC}"

# CPU Load
CPU_LOAD=$(awk '{print $1}' /proc/loadavg 2>/dev/null || echo "0")
echo -n "  CPU 1-min Load Average ($CPU_LOAD): "
if command -v bc &>/dev/null && (( $(echo "$CPU_LOAD > 4.0" | bc -l) )); then
    echo -e "${YELLOW}[WARN] (High load)${NC}"
    record_result "WARN"
else
    echo -e "${GREEN}[PASS]${NC}"
    record_result "PASS"
fi

# RAM Check
RAM_FREE_MB=$(free -m 2>/dev/null | awk '/^Mem:/{print $4+$6+$7}' || echo "0")
RAM_TOTAL_MB=$(free -m 2>/dev/null | awk '/^Mem:/{print $2}' || echo "0")
echo -n "  Available RAM (${RAM_FREE_MB}MB / ${RAM_TOTAL_MB}MB): "
if [ "$RAM_FREE_MB" -lt 256 ] && [ "$RAM_TOTAL_MB" -gt 0 ]; then
    echo -e "${YELLOW}[WARN] (Low memory free)${NC}"
    record_result "WARN"
else
    echo -e "${GREEN}[PASS]${NC}"
    record_result "PASS"
fi

# Disk Space Check
DISK_FREE_GB=$(df -BG / 2>/dev/null | awk 'NR==2 {print $4}' | sed 's/G//' || echo "0")
echo -n "  Free Disk Space on Root / (${DISK_FREE_GB}GB free): "
if [ "$DISK_FREE_GB" -lt 5 ]; then
    echo -e "${RED}[FAIL] (Less than 5GB free)${NC}"
    record_result "FAIL"
elif [ "$DISK_FREE_GB" -lt 10 ]; then
    echo -e "${YELLOW}[WARN] (Less than 10GB free)${NC}"
    record_result "WARN"
else
    echo -e "${GREEN}[PASS]${NC}"
    record_result "PASS"
fi

# ------------------------------------------------------------------------------
# 2. Docker Daemon Check
# ------------------------------------------------------------------------------
echo -e "\n${BOLD}${BLUE}[2/8] Docker Daemon & Core Engine${NC}"
echo -n "  Docker Daemon Responsiveness: "
if ! docker info &>/dev/null; then
    echo -e "${RED}[FAIL] (Docker daemon not responding)${NC}"
    record_result "FAIL"
else
    DOCKER_VERSION=$(docker version --format '{{.Server.Version}}' 2>/dev/null || echo "active")
    echo -e "${GREEN}[PASS] (Version: $DOCKER_VERSION)${NC}"
    record_result "PASS"
fi

# ------------------------------------------------------------------------------
# 3. Docker Networks Verification
# ------------------------------------------------------------------------------
echo -e "\n${BOLD}${BLUE}[3/8] Required Docker Networks${NC}"
REQUIRED_NETWORKS=("neos-public" "neos-private" "neos-database" "neos-storage" "neos-monitoring")

for net in "${REQUIRED_NETWORKS[@]}"; do
    echo -n "  Network '$net': "
    if docker network ls --format '{{.Name}}' 2>/dev/null | grep -Eq "^${net}$"; then
        echo -e "${GREEN}[PASS]${NC}"
        record_result "PASS"
    else
        echo -e "${RED}[FAIL] (Missing network)${NC}"
        record_result "FAIL"
    fi
done

# ------------------------------------------------------------------------------
# 4. Production Container Status & Health
# ------------------------------------------------------------------------------
echo -e "\n${BOLD}${BLUE}[4/8] Production Containers Status & Lifecycle${NC}"

check_container_health() {
    local cname=$1
    local is_critical=$2
    echo -n "  Container '$cname': "
    
    if ! docker ps -a --format '{{.Names}}' 2>/dev/null | grep -Eq "^${cname}$"; then
        if [ "$is_critical" = "true" ]; then
            echo -e "${RED}[FAIL] (Container missing)${NC}"
            record_result "FAIL"
        else
            echo -e "${YELLOW}[WARN] (Optional container not deployed)${NC}"
            record_result "WARN"
        fi
        return
    fi
    
    local status
    status=$(docker inspect -f '{{.State.Status}}' "$cname" 2>/dev/null || echo "unknown")
    
    if [ "$status" != "running" ]; then
        echo -e "${RED}[FAIL] (Status is '$status')${NC}"
        record_result "FAIL"
        return
    fi
    
    local health
    health=$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' "$cname" 2>/dev/null || echo "none")
    
    if [ "$health" = "healthy" ]; then
        echo -e "${GREEN}[PASS] (Running & Healthy)${NC}"
        record_result "PASS"
    elif [ "$health" = "starting" ]; then
        echo -e "${YELLOW}[WARN] (Starting up)${NC}"
        record_result "WARN"
    elif [ "$health" = "unhealthy" ]; then
        echo -e "${RED}[FAIL] (Container UNHEALTHY)${NC}"
        record_result "FAIL"
    else
        echo -e "${GREEN}[PASS] (Running, no healthcheck defined)${NC}"
        record_result "PASS"
    fi
}

check_container_health "neos_traefik" "true"
check_container_health "neos_app" "true"
check_container_health "neos_supabase_gateway" "true"
check_container_health "neos_supabase_auth" "true"
check_container_health "neos_supabase_rest" "true"
check_container_health "neos_supabase_storage" "true"
check_container_health "neos_supabase_realtime" "true"
check_container_health "neos_postgres" "true"
check_container_health "neos_pgbouncer" "true"
check_container_health "neos_redis" "true"
check_container_health "neos_minio" "true"
check_container_health "neos_uptime_kuma" "false"
check_container_health "neos_dashboard" "false"
check_container_health "neos_prometheus" "false"
check_container_health "neos_grafana" "false"

# ------------------------------------------------------------------------------
# 5. Gateway & Backend Inter-Service Probes
# ------------------------------------------------------------------------------
echo -e "\n${BOLD}${BLUE}[5/8] Inter-Service Internal Connectivity${NC}"

# Gateway to Supabase Auth Health
echo -n "  Gateway -> Supabase Auth (:9999/health): "
if docker exec neos_supabase_gateway wget -qO- http://supabase-auth:9999/health 2>/dev/null | grep -q "version"; then
    echo -e "${GREEN}[PASS]${NC}"
    record_result "PASS"
else
    # Fallback direct container probe
    if docker exec neos_supabase_auth wget -qO- http://127.0.0.1:9999/health 2>/dev/null | grep -q "version"; then
        echo -e "${YELLOW}[WARN] (Auth healthy locally, verify gateway network route)${NC}"
        record_result "WARN"
    else
        echo -e "${RED}[FAIL] (Auth health endpoint unreachable)${NC}"
        record_result "FAIL"
    fi
fi

# PostgreSQL Readiness
echo -n "  PostgreSQL Database Ping (pg_isready): "
if docker exec neos_postgres pg_isready -U postgres &>/dev/null; then
    echo -e "${GREEN}[PASS]${NC}"
    record_result "PASS"
else
    echo -e "${RED}[FAIL] (Database not accepting connections)${NC}"
    record_result "FAIL"
fi

# Redis Ping
echo -n "  Redis Cache Ping: "
if docker exec neos_redis redis-cli ping 2>/dev/null | grep -q "PONG"; then
    echo -e "${GREEN}[PASS]${NC}"
    record_result "PASS"
else
    echo -e "${YELLOW}[WARN] (Redis ping failed or requires password)${NC}"
    record_result "WARN"
fi

# MinIO Health
echo -n "  MinIO Storage Health (:9000/minio/health/live): "
if docker exec neos_minio curl -s -f http://localhost:9000/minio/health/live &>/dev/null; then
    echo -e "${GREEN}[PASS]${NC}"
    record_result "PASS"
else
    echo -e "${YELLOW}[WARN] (MinIO health probe check)${NC}"
    record_result "WARN"
fi

# ------------------------------------------------------------------------------
# 6. In-Container Application Health Checks
# ------------------------------------------------------------------------------
echo -e "\n${BOLD}${BLUE}[6/8] In-Container Application Health Endpoints${NC}"

echo -n "  neos_app Internal Endpoint (http://127.0.0.1:3000/api/health): "
APP_HEALTH_OUTPUT=$(docker exec neos_app wget -qO- http://127.0.0.1:3000/api/health 2>/dev/null || echo "")
if echo "$APP_HEALTH_OUTPUT" | grep -q "healthy"; then
    echo -e "${GREEN}[PASS]${NC}"
    record_result "PASS"
else
    echo -e "${RED}[FAIL] (Output: $APP_HEALTH_OUTPUT)${NC}"
    record_result "FAIL"
fi

# ------------------------------------------------------------------------------
# 7. Public Ingress & HTTPS Endpoints Probes
# ------------------------------------------------------------------------------
echo -e "\n${BOLD}${BLUE}[7/8] Public HTTPS Ingress Endpoints${NC}"

check_https_endpoint() {
    local url=$1
    local expected_match=$2
    echo -n "  $url: "
    
    local resp
    resp=$(curl -k -s -S -m 5 "$url" 2>/dev/null || echo "FAILED")
    
    if [ "$resp" = "FAILED" ]; then
        echo -e "${RED}[FAIL] (Connection timed out or network error)${NC}"
        record_result "FAIL"
    elif [ -n "$expected_match" ] && echo "$resp" | grep -q "$expected_match"; then
        echo -e "${GREEN}[PASS]${NC}"
        record_result "PASS"
    elif [ -z "$expected_match" ]; then
        echo -e "${GREEN}[PASS] (Reachable)${NC}"
        record_result "PASS"
    else
        echo -e "${YELLOW}[WARN] (Reachable, body: $(echo "$resp" | head -c 50)...)${NC}"
        record_result "WARN"
    fi
}

check_https_endpoint "https://webapp.neosfacility.com/api/health" "healthy"
check_https_endpoint "https://test.neosfacility.com/api/health" "healthy"
check_https_endpoint "https://webapp.neosfacility.com/login" "NEOS"

# ------------------------------------------------------------------------------
# 8. Persistent Volumes Check
# ------------------------------------------------------------------------------
echo -e "\n${BOLD}${BLUE}[8/8] Docker Volume Integrity${NC}"
CRITICAL_VOLUMES=("postgres_data" "minio_data" "redis_data")

for vol in "${CRITICAL_VOLUMES[@]}"; do
    echo -n "  Volume '$vol': "
    if docker volume ls --format '{{.Name}}' 2>/dev/null | grep -Eq "^${vol}$"; then
        echo -e "${GREEN}[PASS]${NC}"
        record_result "PASS"
    else
        echo -e "${RED}[FAIL] (Volume missing!)${NC}"
        record_result "FAIL"
    fi
done

# ------------------------------------------------------------------------------
# Summary
# ------------------------------------------------------------------------------
echo -e "\n${BLUE}==========================================================================${NC}"
echo -e "${BOLD}                     HEALTH CHECK SUMMARY                                 ${NC}"
echo -e "${BLUE}==========================================================================${NC}"
echo -e "  Passed Checks   : ${GREEN}${BOLD}${TOTAL_PASS}${NC}"
echo -e "  Warnings        : ${YELLOW}${BOLD}${TOTAL_WARN}${NC}"
echo -e "  Failed Checks   : ${RED}${BOLD}${TOTAL_FAIL}${NC}"
echo -e "${BLUE}==========================================================================${NC}"

if [ "$TOTAL_FAIL" -gt 0 ]; then
    echo -e "${RED}${BOLD}OVERALL STATUS: FAILED (Action Required)${NC}"
    exit 1
elif [ "$TOTAL_WARN" -gt 0 ]; then
    echo -e "${YELLOW}${BOLD}OVERALL STATUS: WARNING (System operational with minor warnings)${NC}"
    exit 0
else
    echo -e "${GREEN}${BOLD}OVERALL STATUS: ALL CHECKS PASSED (System Healthy)${NC}"
    exit 0
fi
