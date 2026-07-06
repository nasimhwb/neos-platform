#!/bin/bash
# ==============================================================================
# NEOS PLATFORM BOOTSTRAP - ENTERPRISE PRE-FLIGHT VERIFIER
# ==============================================================================
set -e
set -o pipefail

echo "=========================================================================="
echo "=== Running Enterprise Pre-flight System Verification Checks..."
echo "=========================================================================="

# Helper function to print error and fail fast
fail_check() {
    echo ">>> ERROR: $1"
    echo ">>> System verification failed. Aborting installation."
    exit 1
}

# 1. Check Root Permissions
echo "1. Checking runner permissions..."
if [ "$EUID" -ne 0 ]; then
    fail_check "Bootstrap scripts must be executed with root permissions (sudo)."
fi
echo "   [PASS] Executing as root."

# 2. Verify OS (Target: Ubuntu 24.04 LTS)
echo "2. Verifying Operating System..."
if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo "   Host OS: $NAME ($VERSION)"
    if [[ "$ID" != "ubuntu" ]]; then
        fail_check "Host OS is not Ubuntu. This platform is designed specifically for Ubuntu LTS."
    fi
    if [[ "$VERSION_ID" != "24.04" ]]; then
        echo "   [WARN] Target platform is Ubuntu 24.04 LTS. Current is $NAME $VERSION."
        echo "          We recommend deploying on Ubuntu 24.04. Continuing anyway..."
    fi
else
    fail_check "Cannot identify Host OS. /etc/os-release not found."
fi
echo "   [PASS] OS validation passed."

# 3. Check System CPU and Memory Capacity (KVM2 target: 2 vCPUs, 4GB RAM)
echo "3. Checking system hardware specs..."
CPU_CORES=$(nproc)
TOTAL_MEM=$(free -m | awk '/^Mem:/{print $2}')
echo "   System Capacity: CPU Cores=$CPU_CORES, Total Memory=${TOTAL_MEM}MB"

if [ "$CPU_CORES" -lt 1 ]; then
    fail_check "Insufficient CPU capacity. Minimum 1 CPU core required."
fi
if [ "$TOTAL_MEM" -lt 1800 ]; then
    fail_check "Insufficient memory capacity. Minimum 2GB (2000MB) RAM required."
fi
echo "   [PASS] CPU and RAM capacity validation passed."

# 4. Check Disk Space availability (Root partition needs >= 5GB free)
echo "4. Verifying disk storage space..."
FREE_DISK_KB=$(df -k / | awk 'NR==2 {print $4}')
FREE_DISK_GB=$((FREE_DISK_KB / 1024 / 1024))
echo "   Storage capacity: ${FREE_DISK_GB}GB free space on root '/' partition."

if [ "$FREE_DISK_GB" -lt 5 ]; then
    fail_check "Insufficient storage space. Minimum 5GB of free space on root '/' is required."
fi
echo "   [PASS] Disk storage space validation passed."

# 5. Check Network Connection (Ping public DNS)
echo "5. Verifying outbound internet connectivity..."
if ! ping -c 2 -W 3 8.8.8.8 &>/dev/null; then
    fail_check "No internet connection. Cannot ping 8.8.8.8 (Google Public DNS)."
fi
echo "   [PASS] Outbound internet connectivity verified."

# 6. Check DNS Resolution
echo "6. Verifying DNS resolution..."
if ! ping -c 2 -W 3 github.com &>/dev/null && ! curl -s --connect-timeout 3 https://github.com &>/dev/null; then
    fail_check "DNS resolution failed. Cannot resolve or connect to 'github.com'."
fi
echo "   [PASS] DNS resolution verified."

# 7. Check Port Availability (80 & 443 must be free)
echo "7. Verifying ports 80 and 443 availability..."
# Use pure bash /dev/tcp checks to avoid netstat or lsof dependencies
if (echo >/dev/tcp/127.0.0.1/80) &>/dev/null; then
    fail_check "Port 80 is already in use by another service on this host."
fi
if (echo >/dev/tcp/127.0.0.1/443) &>/dev/null; then
    fail_check "Port 443 is already in use by another service on this host."
fi
echo "   [PASS] Ports 80 and 443 are free and available."

# 8. Check Hostname Configuration
echo "8. Checking system hostname..."
HOSTNAME=$(hostname)
if [ -z "$HOSTNAME" ] || [[ "$HOSTNAME" == "localhost" ]]; then
    echo "   [WARN] Hostname is set to '$HOSTNAME'. We recommend setting a valid FQDN."
else
    echo "   Hostname: $HOSTNAME"
fi
echo "   [PASS] Hostname check passed."

echo "=========================================================================="
echo "=== [PASS] All Pre-flight System Verification Checks Completed! ==="
echo "=========================================================================="
