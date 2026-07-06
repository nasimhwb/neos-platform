#!/bin/bash
# ==============================================================================
# NEOS PLATFORM BOOTSTRAP - PRE-FLIGHT VERIFIER
# ==============================================================================
set -e
set -o pipefail

echo "===> Running Pre-flight System Verification Checks..."

# 1. Verify OS (Target: Ubuntu 24.04)
if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo "Host OS detected: $NAME ($VERSION)"
    if [[ "$VERSION_ID" != "24.04" ]]; then
        echo "Warning: Target platform is Ubuntu 24.04 LTS. Current OS is $NAME $VERSION."
        echo "The scripts are designed for 24.04, but will attempt to execute anyway..."
    fi
else
    echo "Error: Cannot identify Host OS. /etc/os-release not found."
    exit 1
fi

# 2. Check System Resources (Target: Hostinger KVM2 - 2 vCPUs, 4GB RAM)
CPU_CORES=$(nproc)
TOTAL_MEM=$(free -m | awk '/^Mem:/{print $2}')
FREE_DISK=$(df -h / | awk 'NR==2 {print $4}')

echo "System Specifications:"
echo "  - CPU Cores: $CPU_CORES"
echo "  - Total Memory: ${TOTAL_MEM}MB"
echo "  - Disk Space Available (Root): $FREE_DISK"

if [ "$CPU_CORES" -lt 1 ]; then
    echo "Error: Infrastructure requires at least 1 CPU core."
    exit 1
fi

if [ "$TOTAL_MEM" -lt 2000 ]; then
    echo "Warning: System has less than 2GB of RAM. The monitoring stack and Postgres cluster might experience Out-Of-Memory (OOM) faults under load."
fi

# 3. Check for root privileges
if [ "$EUID" -ne 0 ]; then
    echo "Error: Bootstrap scripts must be run with root privileges (sudo)."
    exit 1
fi

echo "===> Pre-flight System Verification Passed!"
