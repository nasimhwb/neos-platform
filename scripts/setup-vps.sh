#!/bin/bash
# ==============================================================================
# NEOS PLATFORM - UBUNTU VPS INITIAL SETUP & PROVISIONING SCRIPT
# ==============================================================================
# Target OS: Ubuntu 24.04 LTS (works on 20.04 and 22.04 as well)
# Run this script once on a clean VPS as root or sudo:
#   sudo ./setup-vps.sh

set -e
set -o pipefail

# Ensure script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "Error: Please run this script as root or with sudo."
    exit 1
fi

echo "=== Starting Neos Platform VPS Setup ==="

# ------------------------------------------------------------------------------
# 1. Update and Upgrade System Packages
# ------------------------------------------------------------------------------
echo "--- Updating system packages ---"
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get upgrade -y
apt-get install -y curl git ufw sysstat software-properties-common ca-certificates certbot

# ------------------------------------------------------------------------------
# 2. Install Docker and Docker Compose
# ------------------------------------------------------------------------------
echo "--- Installing Docker and Docker Compose ---"
if ! command -v docker &> /dev/null; then
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc

    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      tee /etc/apt/sources.list.d/docker.list > /dev/null

    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    # Enable and start Docker service
    systemctl enable docker
    systemctl start docker
    echo "Docker installed successfully."
else
    echo "Docker is already installed, skipping."
fi

# ------------------------------------------------------------------------------
# 3. Configure Sysctl Performance Parameters (For Redis and System Scaling)
# ------------------------------------------------------------------------------
echo "--- Tweaking sysctl kernel settings ---"
SYSCTL_CONF="/etc/sysctl.d/99-neos-platform.conf"
if [ ! -f "$SYSCTL_CONF" ]; then
    cat <<EOF > "$SYSCTL_CONF"
# Redis background saving memory overcommit configuration
vm.overcommit_memory = 1

# Maximum open file descriptors
fs.file-max = 2097152

# Network socket backlogs
net.core.somaxconn = 65535
net.ipv4.tcp_max_syn_backlog = 65535

# Virtual memory swapping threshold
vm.swappiness = 10
EOF
    sysctl --system
    echo "Sysctl optimized parameters written to $SYSCTL_CONF."
else
    echo "Sysctl settings already configured."
fi

# ------------------------------------------------------------------------------
# 4. Configure Host Directories & Permissions
# ------------------------------------------------------------------------------
echo "--- Creating shared data and backup directories ---"
mkdir -p /srv/neos/letsencrypt
mkdir -p /srv/neos/www
mkdir -p /srv/neos/backups
mkdir -p /srv/neos/backups/tmp

# Grant Docker appropriate access to mounted filesystems if needed
chmod -R 755 /srv/neos

# ------------------------------------------------------------------------------
# 5. Bootstrap Self-Signed SSL Certificates (Crucial Nginx Bootstrap)
# ------------------------------------------------------------------------------
# Nginx fails to start if ssl_certificate files do not exist.
# We create a dummy self-signed cert for bootstrapping first.
echo "--- Bootstrapping SSL Certificates ---"
# Fetch domain from .env file or default
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$REPO_DIR/.env"
DOMAIN="neos-platform.local"

if [ -f "$ENV_FILE" ]; then
    # Load BASE_DOMAIN variable
    DOMAIN=$(grep -E "^BASE_DOMAIN=" "$ENV_FILE" | cut -d'=' -f2- | xargs)
fi

CERT_DIR="/srv/neos/letsencrypt/live/$DOMAIN"

if [ ! -f "$CERT_DIR/fullchain.pem" ]; then
    echo "No SSL certificate found. Generating dummy self-signed certificate for '$DOMAIN' to allow Nginx to start..."
    mkdir -p "$CERT_DIR"
    
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
      -keyout "$CERT_DIR/privkey.pem" \
      -out "$CERT_DIR/fullchain.pem" \
      -subj "/CN=$DOMAIN/O=Neos Platform Shared/C=US"
      
    echo "Dummy certificates generated successfully at $CERT_DIR."
else
    echo "Existing SSL certificate found, skipping dummy certificate generation."
fi

# ------------------------------------------------------------------------------
# 6. Configure UFW Firewall
# ------------------------------------------------------------------------------
echo "--- Configuring UFW Firewall ---"
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp comment 'SSH'
ufw allow 80/tcp comment 'HTTP'
ufw allow 443/tcp comment 'HTTPS'
ufw --force enable
ufw status verbose

echo "=== VPS Setup Successfully Completed ==="
echo "Next Steps:"
echo "1. Run: cp .env.example .env"
echo "2. Edit .env and configure all variables & credentials."
echo "3. Spin up the infrastructure: docker compose up -d"
echo "4. Run Certbot to replace dummy certs with Let's Encrypt certificates:"
echo "   sudo certbot certonly --webroot -w /srv/neos/www -d $DOMAIN -d erp.$DOMAIN -d crm.$DOMAIN -d hrms.$DOMAIN -d billing.$DOMAIN -d inventory.$DOMAIN -d s3.$DOMAIN -d s3-console.$DOMAIN -d monitor.$DOMAIN"
