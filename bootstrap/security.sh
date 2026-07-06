#!/bin/bash
# ==============================================================================
# NEOS PLATFORM BOOTSTRAP - SECURITY PROVISIONER
# ==============================================================================
set -e
set -o pipefail

echo "===> [4/6] Running System Security Configuration..."

# 1. Apply Sysctl Kernel Tuning Parameters
# Configures memory overcommit for Redis and raises file descriptor maximums.
echo "Applying sysctl security and performance configuration..."
SYSCTL_CONF="/etc/sysctl.d/99-neos-platform.conf"

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

# Reload parameters
sysctl --system

# 2. Configure UFW Firewall
echo "Setting up UFW rules..."
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp comment 'SSH'
ufw allow 80/tcp comment 'HTTP'
ufw allow 443/tcp comment 'HTTPS'
ufw --force enable

# 3. Bootstrap SSL Dummy Certificate
# Nginx fails to boot if referenced SSL files do not exist.
# We create a self-signed cert for bootstrapping first.
BOOTSTRAP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$BOOTSTRAP_DIR")"
ENV_FILE="$REPO_DIR/.env"
DOMAIN="neos-platform.local"

if [ -f "$ENV_FILE" ]; then
    # Load domain name if defined in .env
    DOMAIN=$(grep -E "^BASE_DOMAIN=" "$ENV_FILE" | cut -d'=' -f2- | xargs)
fi

CERT_DIR="/srv/neos/letsencrypt/live/$DOMAIN"

if [ ! -f "$CERT_DIR/fullchain.pem" ]; then
    echo "SSL certificate missing. Generating dummy self-signed certificate for '$DOMAIN'..."
    mkdir -p "$CERT_DIR"
    
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
      -keyout "$CERT_DIR/privkey.pem" \
      -out "$CERT_DIR/fullchain.pem" \
      -subj "/CN=$DOMAIN/O=Neos Platform Shared/C=US"
      
    echo "Dummy certificates successfully created at $CERT_DIR."
else
    echo "Existing SSL certificate found. Skipping dummy creation."
fi

echo "===> System Security Configuration Complete!"
