#!/bin/bash
# ==============================================================================
# NEOS PLATFORM BOOTSTRAP - PRODUCTION SYSTEM VERIFIER
# ==============================================================================
# Performs pre-flight and post-flight validation checks.
# Usage: 
#   ./verify.sh --pre     (Pre-flight checks, before installation)
#   ./verify.sh --post    (Post-flight checks, after installation)
# ==============================================================================
set -e
set -o pipefail

# ANSI color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

MODE="--post"
if [ "$1" == "--pre" ] || [ "$1" == "--post" ]; then
    MODE="$1"
else
    # Auto-detect mode: if docker is not installed, default to pre-flight
    if ! command -v docker &>/dev/null; then
        MODE="--pre"
    fi
fi

echo -e "${BLUE}==========================================================================${NC}"
echo -e "${BLUE}=== Running Neos Platform System Verification Checks (${MODE}) ===${NC}"
echo -e "${BLUE}==========================================================================${NC}"

# Helper function to print error and fail fast
fail_check() {
    echo -e "${RED}>>> ERROR: $1${NC}"
    echo -e "${RED}>>> System verification failed. Aborting.${NC}"
    exit 1
}

# 1. Check Root Permissions
echo -n "1. Checking runner permissions... "
if [ "$EUID" -ne 0 ]; then
    fail_check "Verification script must be executed with root permissions (sudo)."
fi
echo -e "${GREEN}[PASS] Root verified.${NC}"

# 2. Verify OS (Target: Ubuntu 24.04 LTS)
echo -n "2. Verifying Operating System... "
if [ -f /etc/os-release ]; then
    . /etc/os-release
    if [[ "$ID" != "ubuntu" ]]; then
        fail_check "Host OS is $NAME ($VERSION). Only Ubuntu is supported."
    fi
    if [[ "$VERSION_ID" != "24.04" ]]; then
        fail_check "Ubuntu version is $VERSION_ID. The platform requires Ubuntu 24.04 LTS strictly."
    fi
else
    fail_check "/etc/os-release not found. Cannot verify operating system."
fi
echo -e "${GREEN}[PASS] OS is Ubuntu 24.04 LTS.${NC}"

# 3. Check System CPU and Memory Capacity (KVM2 target: 2 vCPUs, 4GB RAM)
echo -n "3. Verifying CPU capacity... "
CPU_CORES=$(nproc)
if [ "$CPU_CORES" -lt 2 ]; then
    fail_check "Insufficient CPU capacity. KVM2 VPS requires at least 2 CPU cores (Detected: $CPU_CORES)."
fi
echo -e "${GREEN}[PASS] Detected $CPU_CORES CPU cores.${NC}"

echo -n "4. Verifying RAM capacity... "
TOTAL_MEM=$(free -m | awk '/^Mem:/{print $2}')
# 3500MB allows some memory to be reserved/overhead by hypervisor
if [ "$TOTAL_MEM" -lt 3500 ]; then
    fail_check "Insufficient RAM. Hostinger KVM2 VPS requires at least 4GB (4000MB) RAM (Detected: ${TOTAL_MEM}MB)."
fi
echo -e "${GREEN}[PASS] Detected ${TOTAL_MEM}MB total memory.${NC}"

# 4. Check Disk Space availability (Root partition needs >= 10GB free)
echo -n "5. Verifying disk storage space... "
FREE_DISK_KB=$(df -k / | awk 'NR==2 {print $4}')
FREE_DISK_GB=$((FREE_DISK_KB / 1024 / 1024))
if [ "$FREE_DISK_GB" -lt 10 ]; then
    fail_check "Insufficient storage space. Root '/' partition requires at least 10GB free (Detected: ${FREE_DISK_GB}GB)."
fi
echo -e "${GREEN}[PASS] Detected ${FREE_DISK_GB}GB free space on root '/' partition.${NC}"

# 5. Check Network Connection (Ping public DNS)
echo -n "6. Verifying outbound internet connectivity... "
if ! ping -c 2 -W 3 8.8.8.8 &>/dev/null; then
    fail_check "No internet connection. Cannot ping 8.8.8.8 (Google Public DNS)."
fi
echo -e "${GREEN}[PASS] Internet connection is active.${NC}"

# 6. Check DNS Resolution
echo -n "7. Verifying DNS resolution... "
if ! host github.com &>/dev/null && ! nslookup github.com &>/dev/null && ! curl -s -I --connect-timeout 3 https://github.com &>/dev/null; then
    fail_check "DNS resolution failed. Cannot resolve 'github.com'."
fi
echo -e "${GREEN}[PASS] DNS resolution functional.${NC}"

# 7. Check Port Availability (80, 443, 9000 must be free in pre-flight)
if [ "$MODE" == "--pre" ]; then
    echo -n "8. Checking required ports availability (80, 443, 9000)... "
    if (echo >/dev/tcp/127.0.0.1/80) &>/dev/null; then
        fail_check "Port 80 is already in use by another service on this host."
    fi
    if (echo >/dev/tcp/127.0.0.1/443) &>/dev/null; then
        fail_check "Port 443 is already in use by another service on this host."
    fi
    if (echo >/dev/tcp/127.0.0.1/9000) &>/dev/null; then
        fail_check "Port 9000 is already in use by another service on this host."
    fi
    echo -e "${GREEN}[PASS] Ports 80, 443, and 9000 are free.${NC}"
fi

# 8. Firewall Status Verification
if [ "$MODE" == "--post" ]; then
    echo -n "8. Verifying UFW firewall status... "
    if ! command -v ufw &>/dev/null; then
        fail_check "UFW firewall tool is not installed."
    fi
    UFW_STATUS=$(ufw status | head -n 1)
    if [[ "$UFW_STATUS" != *"active"* ]]; then
        fail_check "UFW is installed but not active. Secure state requires active firewall."
    fi
    
    # Check key ports are allowed in rules
    UFW_RULES=$(ufw status)
    if ! echo "$UFW_RULES" | grep -E '22/tcp.*ALLOW' &>/dev/null && ! echo "$UFW_RULES" | grep -E '22.*ALLOW' &>/dev/null; then
        fail_check "Firewall configuration error: SSH Port 22 is not allowed."
    fi
    if ! echo "$UFW_RULES" | grep -E '80/tcp.*ALLOW' &>/dev/null && ! echo "$UFW_RULES" | grep -E '80.*ALLOW' &>/dev/null; then
        fail_check "Firewall configuration error: HTTP Port 80 is not allowed."
    fi
    if ! echo "$UFW_RULES" | grep -E '443/tcp.*ALLOW' &>/dev/null && ! echo "$UFW_RULES" | grep -E '443.*ALLOW' &>/dev/null; then
        fail_check "Firewall configuration error: HTTPS Port 443 is not allowed."
    fi
    echo -e "${GREEN}[PASS] UFW is active and configured correctly.${NC}"
else
    echo -n "8. Verifying UFW tool installation... "
    if ! command -v ufw &>/dev/null; then
        fail_check "UFW firewall tool is not installed."
    fi
    echo -e "${GREEN}[PASS] UFW tool is installed.${NC}"
fi

# 9. Docker and Docker Compose Plugin checks (Only in post-flight)
if [ "$MODE" == "--post" ]; then
    echo -n "9. Verifying Docker Engine installation... "
    if ! command -v docker &>/dev/null; then
        fail_check "Docker Engine is not installed."
    fi
    if ! systemctl is-active --quiet docker; then
        fail_check "Docker service is installed but not running."
    fi
    if ! docker info &>/dev/null; then
        fail_check "Docker daemon is running but cannot be accessed (permissions issue)."
    fi
    echo -e "${GREEN}[PASS] Docker Engine is running.${NC}"

    echo -n "10. Verifying Docker Compose plugin installation... "
    if ! docker compose version &>/dev/null; then
        fail_check "Docker Compose plugin is not installed or not working."
    fi
    echo -e "${GREEN}[PASS] Docker Compose plugin is working ($(docker compose version | awk '{print $4}')).${NC}"
fi

echo -e "${BLUE}==========================================================================${NC}"
echo -e "${GREEN}=== [PASS] All system verification checks completed successfully! ===${NC}"
echo -e "${BLUE}==========================================================================${NC}"
exit 0
