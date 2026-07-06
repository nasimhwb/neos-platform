#!/bin/bash
# ==============================================================================
# NEOS PLATFORM BOOTSTRAP - UBUNTU SYSTEM UTILITIES INSTALLER
# ==============================================================================
set -e
set -o pipefail

echo "===> [1/6] Running Ubuntu Package Provisioning..."

# Ensure non-interactive front-end is set
export DEBIAN_FRONTEND=noninteractive

# Update system package registry
echo "Updating apt repositories..."
apt-get update

# Install basic development and networking packages
echo "Installing core operating system utilities..."
apt-get install -y --no-install-recommends \
    apt-transport-https \
    ca-certificates \
    curl \
    git \
    gnupg \
    lsb-release \
    software-properties-common \
    ufw \
    openssl \
    jq \
    rclone \
    unzip \
    zip \
    tar

# Clean apt cache to reduce VPS storage usage
apt-get clean
rm -rf /var/lib/apt/lists/*

echo "===> Ubuntu Package Provisioning Complete!"
