#!/bin/bash
# ==============================================================================
# NEOS PLATFORM BOOTSTRAP - DOCKER PROD CONFIG & INSTALLER
# ==============================================================================
set -e
set -o pipefail

echo "===> Running Production Docker Setup..."

# Install GPG key for official Docker repository
if [ ! -f /etc/apt/keyrings/docker.asc ]; then
    echo "Installing Docker repository GPG key..."
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.download.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc || \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc
fi

# Add the repository to Apt sources
if [ ! -f /etc/apt/sources.list.d/docker.list ]; then
    echo "Adding Docker repository to Apt sources list..."
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      tee /etc/apt/sources.list.d/docker.list > /dev/null
fi

# Install packages
echo "Updating apt repositories and installing Docker packages..."
apt-get update
apt-get install -y --no-install-recommends \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

# ------------------------------------------------------------------------------
# Production Daemon Configuration (/etc/docker/daemon.json)
# ------------------------------------------------------------------------------
echo "Configuring production Docker daemon parameters..."
mkdir -p /etc/docker
cat <<EOF > /etc/docker/daemon.json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "50m",
    "max-file": "3"
  },
  "dns": ["8.8.8.8", "1.1.1.1"],
  "live-restore": true,
  "userland-proxy": false,
  "no-new-privileges": true,
  "default-ulimits": {
    "nofile": {
      "Name": "nofile",
      "Hard": 64000,
      "Soft": 64000
    }
  }
}
EOF

# Restart Docker to apply daemon.json changes
echo "Enabling and restarting Docker service..."
systemctl daemon-reload
systemctl enable docker
systemctl restart docker

# Validate installation
echo "Checking Docker version details..."
docker --version
docker compose version

echo "===> Production Docker Setup Complete!"
