#!/bin/bash
# ==============================================================================
# NEOS PLATFORM BOOTSTRAP - SECURITY PROVISIONER
# ==============================================================================
set -e
set -o pipefail

echo "===> Running System Security Hardening & User Provisioning..."

# 1. Provision Deployment User 'nasim'
echo "Checking for deployment user 'nasim'..."
if ! id "nasim" &>/dev/null; then
    echo "Creating deployment user 'nasim'..."
    useradd -m -s /bin/bash nasim
    # Grant sudo permissions
    usermod -aG sudo nasim
    
    # Configure passwordless sudo for nasim (required for GHA automation running targets)
    echo "nasim ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/99-nasim
    chmod 0440 /etc/sudoers.d/99-nasim
    echo "Deployment user 'nasim' successfully created."
else
    echo "Deployment user 'nasim' already exists."
fi

# Ensure nasim is added to the docker group
if getent group docker >/dev/null; then
    echo "Adding nasim to the docker group..."
    usermod -aG docker nasim
else
    echo "Warning: docker group not found. Will add nasim on docker setup."
fi

# 2. Apply Sysctl Kernel Tuning Parameters
echo "Applying sysctl configurations..."
SYSCTL_CONF="/etc/sysctl.d/99-neos-platform.conf"
cat <<EOF > "$SYSCTL_CONF"
# Redis memory overcommit setting
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

# 3. Configure Host UFW Firewall
echo "Applying UFW firewall rules..."
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp comment 'SSH Secure Access'
ufw allow 80/tcp comment 'HTTP Web Verification'
ufw allow 443/tcp comment 'HTTPS Proxy Ingress'
ufw --force enable
ufw status verbose

# 4. Bootstrap SSL Dummy Certificate
BOOTSTRAP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$BOOTSTRAP_DIR")"
ENV_FILE="$REPO_DIR/.env"
DOMAIN="neos-platform.local"

if [ -f "$ENV_FILE" ]; then
    DOMAIN=$(grep -E "^BASE_DOMAIN=" "$ENV_FILE" | cut -d'=' -f2- | xargs)
fi

CERT_DIR="/srv/neos/shared/ssl/live/$DOMAIN"

if [ ! -f "$CERT_DIR/fullchain.pem" ]; then
    echo "SSL certificate missing. Generating dummy self-signed certificate for bootstrap domain '$DOMAIN'..."
    mkdir -p "$CERT_DIR"
    
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
      -keyout "$CERT_DIR/privkey.pem" \
      -out "$CERT_DIR/fullchain.pem" \
      -subj "/CN=$DOMAIN/O=Neos Platform Shared/C=US"
      
    echo "Dummy certificates successfully created at $CERT_DIR."
else
    echo "Existing SSL certificate found. Skipping dummy creation."
fi

# 5. Configure Daily Logical Backups Cron Job
echo "Configuring daily backup cron job..."
CRON_FILE="/etc/cron.d/neos-platform-backup"
# Resolve repository root
BOOTSTRAP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$BOOTSTRAP_DIR")"
# Write cron job
echo "0 2 * * * root /bin/bash $REPO_DIR/backups/backup.sh >> /srv/neos/shared/logs/system/backup.log 2>&1" > "$CRON_FILE"
chmod 0644 "$CRON_FILE"
echo "Daily backup cron job registered at $CRON_FILE."

echo "===> System Security Hardening Complete!"
