#!/bin/bash
# ==============================================================================
# NEOS PLATFORM - SYSTEM HEALTH DIAGNOSTIC UTILITY (DOCTOR)
# ==============================================================================
# Performs diagnostic audits on host resources, UFW status, Docker containers,
# proxy connections, and certificates. Ignores unprovisioned services gracefully.
# Usage: ./doctor.sh
# ==============================================================================
set -e
set -o pipefail

# ANSI color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}==========================================================================${NC}"
echo -e "${BLUE}           NEOS PLATFORM DIAGNOSTIC ENGINE (make doctor)                  ${NC}"
echo -e "${BLUE}==========================================================================${NC}"

# 1. System Hardware Health Check
echo -e "\n${BLUE}--- [1/6] Auditing System Host Resources ---${NC}"

# CPU Load Check
CPU_LOAD=$(cat /proc/loadavg | awk '{print $1}')
echo -n "Checking CPU Load Average: "
if (( $(echo "$CPU_LOAD > 2.0" | bc -l) )); then
    echo -e "${YELLOW}WARN (Load=$CPU_LOAD is high)${NC}"
else
    echo -e "${GREEN}PASS (Load=$CPU_LOAD)${NC}"
fi

# RAM Check
RAM_FREE=$(free -m | awk '/^Mem:/{print $4}')
RAM_TOTAL=$(free -m | awk '/^Mem:/{print $2}')
echo -n "Checking Available Memory: "
if [ "$RAM_FREE" -lt 256 ]; then
    echo -e "${YELLOW}WARN (${RAM_FREE}MB free out of ${RAM_TOTAL}MB)${NC}"
else
    echo -e "${GREEN}PASS (${RAM_FREE}MB free out of ${RAM_TOTAL}MB)${NC}"
fi

# Disk Space Check
DISK_FREE_GB=$(df -h / | awk 'NR==2 {print $4}' | sed 's/G//')
echo -n "Checking Free Disk Space (Root /): "
if [ "${DISK_FREE_GB%.*}" -lt 5 ]; then
    echo -e "${RED}FAIL (${DISK_FREE_GB}GB left)${NC}"
else
    echo -e "${GREEN}PASS (${DISK_FREE_GB}GB left)${NC}"
fi

# Firewall Status
echo -n "Checking Firewall (UFW) status: "
if command -v ufw &>/dev/null; then
    UFW_STATUS=$(ufw status | head -n 1)
    if [[ "$UFW_STATUS" == *"active"* ]]; then
        echo -e "${GREEN}PASS (Active)${NC}"
    else
        echo -e "${YELLOW}WARN (Installed but Inactive)${NC}"
    fi
else
    echo -e "${RED}FAIL (UFW not installed)${NC}"
fi

# 2. Docker Daemon Check
echo -e "\n${BLUE}--- [2/6] Auditing Docker Daemon Status ---${NC}"
echo -n "Checking Docker daemon status: "
if ! docker info &>/dev/null; then
    echo -e "${RED}FAIL (Docker daemon not running or access denied)${NC}"
else
    echo -e "${GREEN}PASS (Daemon is healthy)${NC}"
fi

# 3. Docker Containers Lifecycle & Health
echo -e "\n${BLUE}--- [3/6] Auditing Infrastructure Containers Status ---${NC}"

check_container() {
    local name=$1
    local type=${2:-core}
    echo -n "Container '$name': "
    if ! docker ps -a --format '{{.Names}}' | grep -Eq "^${name}$"; then
        if [ "$type" = "core" ]; then
            echo -e "${RED}FAIL (Not created/missing)${NC}"
            return 1
        else
            echo -e "${YELLOW}NOT DEPLOYED (Skipped)${NC}"
            return 0
        fi
    fi
    
    local status
    status=$(docker inspect -f '{{.State.Status}}' "$name")
    
    if [ "$status" != "running" ]; then
        echo -e "${RED}FAIL (State is '$status')${NC}"
        return 1
    fi
    
    # Check health status if defined
    local health
    health=$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' "$name")
    
    if [ "$health" = "unhealthy" ]; then
        echo -e "${RED}FAIL (Container is running but UNHEALTHY)${NC}"
        return 1
    elif [ "$health" = "starting" ]; then
        echo -e "${YELLOW}WARN (Container is starting)${NC}"
    else
        echo -e "${GREEN}PASS (Running/Healthy)${NC}"
    fi
}

# Core platform containers (must be present & running)
check_container "neos_traefik" "core"
check_container "neos_portainer" "core"
check_container "neos_postgres" "core"
check_container "neos_pgbouncer" "core"
check_container "neos_redis" "core"
check_container "neos_minio" "core"
check_container "neos_prometheus" "core"
check_container "neos_grafana" "core"

# 4. Service Endpoint Connectivity Checks
echo -e "\n${BLUE}--- [4/6] Auditing Service Endpoints API Connectivity ---${NC}"

is_running() {
    docker ps --filter "name=$1" --filter "status=running" --format '{{.Names}}' | grep -q "$1"
}

# Traefik port 80 check
echo -n "Checking Traefik Proxy port 80: "
if ! is_running "neos_traefik"; then
    echo -e "${YELLOW}SKIPPED (Proxy container not running)${NC}"
elif curl -s -I http://localhost:80/ &>/dev/null; then
    echo -e "${GREEN}PASS (HTTP responds)${NC}"
else
    echo -e "${RED}FAIL (Traefik port 80 not responding)${NC}"
fi

# Portainer check
echo -n "Checking Portainer access on port 9000: "
if ! is_running "neos_portainer"; then
    echo -e "${YELLOW}SKIPPED (Portainer container not running)${NC}"
elif curl -s -I http://localhost:9000/ &>/dev/null; then
    echo -e "${GREEN}PASS (HTTP responds)${NC}"
else
    echo -e "${RED}FAIL (Portainer not responding)${NC}"
fi

# PostgreSQL connectivity test
echo -n "Checking PostgreSQL database access: "
if ! is_running "neos_postgres"; then
    echo -e "${YELLOW}SKIPPED (Postgres container not running)${NC}"
elif docker exec neos_postgres pg_isready -U postgres &>/dev/null; then
    echo -e "${GREEN}PASS (Database answers queries)${NC}"
fi

# PgBouncer connection pooler check
echo -n "Checking PgBouncer connection pooler on port 6432: "
if ! is_running "neos_pgbouncer"; then
    echo -e "${YELLOW}SKIPPED (PgBouncer container not running)${NC}"
elif (echo >/dev/tcp/127.0.0.1/6432) &>/dev/null; then
    echo -e "${GREEN}PASS (Listener active)${NC}"
else
    echo -e "${RED}FAIL (PgBouncer listener port 6432 not responding)${NC}"
fi

# Redis connectivity test
echo -n "Checking Redis Cache connectivity: "
if ! is_running "neos_redis"; then
    echo -e "${YELLOW}SKIPPED (Redis container not running)${NC}"
else
    REDIS_PASS=$(docker exec neos_redis printenv REDIS_PASSWORD 2>/dev/null || echo "")
    if docker exec neos_redis redis-cli ping &>/dev/null || [ -n "$REDIS_PASS" ] && docker exec neos_redis redis-cli -a "$REDIS_PASS" ping 2>/dev/null | grep -q PONG; then
        echo -e "${GREEN}PASS (Redis cache answers PING)${NC}"
    else
        echo -e "${RED}FAIL (Redis cache unreachable)${NC}"
    fi
fi

# MinIO endpoint check
echo -n "Checking MinIO Storage health endpoint: "
if ! is_running "neos_minio"; then
    echo -e "${YELLOW}SKIPPED (MinIO container not running)${NC}"
elif docker exec neos_minio curl -s http://localhost:9000/minio/health/live &>/dev/null; then
    echo -e "${GREEN}PASS (Storage reports healthy)${NC}"
else
    echo -e "${RED}FAIL (MinIO storage unreachable)${NC}"
fi

# Prometheus check
echo -n "Checking Prometheus metrics endpoint: "
if ! is_running "neos_prometheus"; then
    echo -e "${YELLOW}SKIPPED (Prometheus container not running)${NC}"
elif docker exec neos_prometheus curl -s http://localhost:9090/-/healthy &>/dev/null; then
    echo -e "${GREEN}PASS (Metrics server reports healthy)${NC}"
else
    echo -e "${RED}FAIL (Prometheus metrics unreachable)${NC}"
fi

# Grafana check
echo -n "Checking Grafana Dashboard API endpoint: "
if ! is_running "neos_grafana"; then
    echo -e "${YELLOW}SKIPPED (Grafana container not running)${NC}"
elif docker exec neos_grafana curl -s http://localhost:3000/api/health &>/dev/null; then
    echo -e "${GREEN}PASS (Dashboard API responds)${NC}"
else
    echo -e "${RED}FAIL (Grafana dashboards unreachable)${NC}"
fi

# 5. SSL Certificates check
echo -e "\n${BLUE}--- [5/6] Auditing SSL Certificates Status ---${NC}"
BOOTSTRAP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$BOOTSTRAP_DIR")"
ENV_FILE="$REPO_DIR/.env"
DOMAIN="neos-platform.local"
if [ -f "$ENV_FILE" ]; then
    DOMAIN=$(grep -E "^BASE_DOMAIN=" "$ENV_FILE" | cut -d'=' -f2- | xargs)
fi

CERT_FILE="/srv/neos/shared/ssl/live/$DOMAIN/fullchain.pem"
echo -n "Checking SSL Certificate file: "
if [ -f "$CERT_FILE" ]; then
    # Verify expiration
    EXPIRY_DATE=$(openssl x509 -enddate -noout -in "$CERT_FILE" | cut -d'=' -f2-)
    EXPIRY_EPOCH=$(date -d "$EXPIRY_DATE" +%s)
    CURRENT_EPOCH=$(date +%s)
    DAYS_LEFT=$(( (EXPIRY_EPOCH - CURRENT_EPOCH) / 86400 ))
    
    if [ "$DAYS_LEFT" -lt 0 ]; then
        echo -e "${RED}FAIL (EXPIRED on $EXPIRY_DATE)${NC}"
    elif [ "$DAYS_LEFT" -lt 30 ]; then
        echo -e "${YELLOW}WARN (Expiring soon on $EXPIRY_DATE, $DAYS_LEFT days remaining)${NC}"
    else
        echo -e "${GREEN}PASS (Valid until $EXPIRY_DATE, $DAYS_LEFT days remaining)${NC}"
    fi
else
    echo -e "${YELLOW}WARN (No certificate file found at $CERT_FILE)${NC}"
fi

# 6. DNS Records resolution check
echo -e "\n${BLUE}--- [6/6] Auditing Domain DNS Resolution ---${NC}"
echo -n "Checking DNS resolution for host domain '$DOMAIN': "
if ping -c 1 -W 2 "$DOMAIN" &>/dev/null || host "$DOMAIN" &>/dev/null || nslookup "$DOMAIN" &>/dev/null; then
    echo -e "${GREEN}PASS (Domain resolves)${NC}"
else
    echo -e "${YELLOW}WARN (Cannot resolve host domain '$DOMAIN' locally)${NC}"
fi

echo -e "\n${BLUE}==========================================================================${NC}"
echo -e "${GREEN}Diagnostic check completed. Run 'make logs service=<name>' for container logs.${NC}"
echo -e "${BLUE}==========================================================================${NC}"
