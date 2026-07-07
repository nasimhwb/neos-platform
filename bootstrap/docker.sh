#!/bin/bash
# ==============================================================================
# NEOS PLATFORM BOOTSTRAP - PRODUCTION DOCKER PROVISIONER
# ==============================================================================
# Installs Docker Engine from official repositories, applies production daemon.json
# configurations (logging, BuildKit, overlay2, live-restore, optional IPv6), 
# pre-provisions networks, and validates runtime health.
#
# Usage: sudo ./docker.sh

set -e
set -o pipefail

echo "=========================================================================="
echo "=== Running Production Docker Setup..."
echo "=========================================================================="

# Ensure script is executed as root
if [ "$EUID" -ne 0 ]; then
    echo "ERROR: Docker setup must be executed with root permissions (sudo)."
    exit 1
fi

# 1. cgroup v2 compatibility check
echo "1. Checking cgroup v2 compatibility..."
if grep -q "cgroup2" /proc/filesystems; then
    echo "   [PASS] cgroup v2 is enabled in host kernel filesystems."
else
    echo "   [WARN] cgroup v2 is not active. Resource constraints may not be fully enforced."
fi

# 2. Check if Docker is already installed (Idempotency check)
DOCKER_INSTALLED=false
if command -v docker &>/dev/null; then
    echo "   Docker Engine is already installed on the host."
    docker --version
    DOCKER_INSTALLED=true
fi

# 3. Add official Docker repository and install if missing
if [ "$DOCKER_INSTALLED" = false ]; then
    echo "2. Installing Docker Engine from official repositories..."
    
    # Install dependency packages
    apt-get update
    apt-get install -y ca-certificates curl gnupg

    # Create keyring folder and download GPG key
    install -m 0755 -d /etc/apt/keyrings
    if [ ! -f /etc/apt/keyrings/docker.asc ]; then
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
        chmod a+r /etc/apt/keyrings/docker.asc
    fi

    # Register Docker sources list
    if [ ! -f /etc/apt/sources.list.d/docker.list ]; then
        echo "Adding Docker repository to APT sources list..."
        echo \
          "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
          $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
          tee /etc/apt/sources.list.d/docker.list > /dev/null
    fi

    # Install Docker packages
    apt-get update
    apt-get install -y --no-install-recommends \
        docker-ce \
        docker-ce-cli \
        containerd.io \
        docker-buildx-plugin \
        docker-compose-plugin
        
    echo "   [PASS] Docker Engine and Compose packages successfully installed."
else
    echo "2. Skipping Docker installation (packages already present)."
fi

# 4. Probe for IPv6 support
echo "3. Probing for Host IPv6 default route support..."
ipv6_supported=false

if [ -f /proc/sys/net/ipv6/conf/all/disable_ipv6 ] && [ "$(cat /proc/sys/net/ipv6/conf/all/disable_ipv6)" -eq 0 ]; then
    # Check if a default IPv6 route is active on the network interface card
    if ip -6 route show | grep -q "default"; then
        ipv6_supported=true
        echo "   IPv6 Default Route detected."
    else
        echo "   No IPv6 Default Route active. Omiting IPv6 configurations."
    fi
else
    echo "   IPv6 is disabled at the system level. Omiting IPv6 configurations."
fi

# 5. Production Daemon Configuration (/etc/docker/daemon.json)
echo "4. Generating production Docker daemon configurations..."
DAEMON_CONF="/etc/docker/daemon.json"
mkdir -p /etc/docker

# Generate production JSON base configuration
cat <<EOF > "$DAEMON_CONF"
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
  "storage-driver": "overlay2",
  "features": {
    "buildkit": true
  },
  "default-ulimits": {
    "nofile": {
      "Name": "nofile",
      "Hard": 64000,
      "Soft": 64000
    }
  }
}
EOF

# Inject IPv6 attributes if supported
if [ "$ipv6_supported" = true ]; then
    echo "   Adding fixed-cidr-v6 subnet and ip6tables rules..."
    if command -v jq &>/dev/null; then
        tmp_json=$(mktemp)
        jq '. + {"ipv6": true, "fixed-cidr-v6": "fd00::/80", "ip6tables": true}' "$DAEMON_CONF" > "$tmp_json"
        mv "$tmp_json" "$DAEMON_CONF"
    else
        # Fallback to python or inline sed if jq isn't available yet
        python3 -c "import json; d=json.load(open('$DAEMON_CONF')); d.update({'ipv6': True, 'fixed-cidr-v6': 'fd00::/80', 'ip6tables': True}); json.dump(d, open('$DAEMON_CONF', 'w'), indent=2)" 2>/dev/null || true
    fi
fi

# Restart daemon to apply updates
echo "   Restarting Docker daemon..."
systemctl daemon-reload
systemctl enable docker
systemctl restart docker
echo "   [PASS] Docker daemon configurations successfully applied."

# 6. Automatic Network Pre-provisioning
echo "5. Pre-provisioning isolated Docker networks..."
create_network() {
    local net_name=$1
    if ! docker network inspect "$net_name" &>/dev/null; then
        echo "   Creating network: $net_name"
        docker network create "$net_name"
    else
        echo "   Network '$net_name' already exists (skipping)."
    fi
}

create_network "neos-public"
create_network "neos-private"
create_network "neos-storage"
create_network "neos-monitoring"
create_network "neos-database"
echo "   [PASS] Docker networks successfully configured."

# 7. Verification and Health Checks
echo "6. Performing Docker Engine health and Compose validations..."

# Test Docker execution capability
echo -n "   Testing container execution (hello-world): "
if docker run --rm alpine:3.19 echo "PASS" &>/dev/null; then
    echo -e "\033[0;32mOK\033[0m"
else
    echo -e "\033[0;31mFAILED\033[0m"
    echo "ERROR: Failed to spin up a test container."
    exit 1
fi

# Test Docker Compose version
echo -n "   Testing Docker Compose plugin availability: "
if docker compose version &>/dev/null; then
    echo -e "\033[0;32mOK ($(docker compose version | awk '{print $4}'))\033[0m"
else
    echo -e "\033[0;31mFAILED\033[0m"
    echo "ERROR: Docker Compose plugin not responding."
    exit 1
fi

echo "=========================================================================="
echo "=== [PASS] Production Docker Configuration Completed Successfully! ==="
echo "=========================================================================="
