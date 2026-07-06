#!/bin/bash
# ==============================================================================
# NEOS PLATFORM BOOTSTRAP - CAPISTRANO DIRECTORY INITIALIZER
# ==============================================================================
set -e

echo "===> Running Release Directories Provisioning..."

# Define layout directories
BASE_DIR="/srv/neos"
RELEASES_DIR="$BASE_DIR/releases"
SHARED_DIR="$BASE_DIR/shared"

DATA_DIR="$SHARED_DIR/data"
BACKUP_DIR="$SHARED_DIR/backups"
LOGS_DIR="$SHARED_DIR/logs"
SSL_DIR="$SHARED_DIR/ssl"
WWW_DIR="$SHARED_DIR/www"

# 1. Create Base Directories
echo "Creating release directory trees..."
mkdir -p "$RELEASES_DIR"
mkdir -p "$SHARED_DIR"
mkdir -p "$DATA_DIR"
mkdir -p "$BACKUP_DIR"
mkdir -p "$BACKUP_DIR/tmp"
mkdir -p "$LOGS_DIR"
mkdir -p "$SSL_DIR"
mkdir -p "$WWW_DIR"

# 2. Create Service Persistent Volumes inside shared/data
echo "Creating service volumes inside shared/data..."
mkdir -p "$DATA_DIR/postgres"
mkdir -p "$DATA_DIR/redis"
mkdir -p "$DATA_DIR/minio"
mkdir -p "$DATA_DIR/prometheus"
mkdir -p "$DATA_DIR/grafana"
mkdir -p "$DATA_DIR/loki"
mkdir -p "$DATA_DIR/portainer"
mkdir -p "$DATA_DIR/uptime-kuma"
mkdir -p "$DATA_DIR/alertmanager"

# Create logs folders
mkdir -p "$LOGS_DIR/nginx"
mkdir -p "$LOGS_DIR/postgres"
mkdir -p "$LOGS_DIR/redis"
mkdir -p "$LOGS_DIR/system"

# 3. Secure and Assign Permissions to nasim user
echo "Assigning directories ownership to nasim:nasim..."
# Ensure the nasim user exists first (security.sh runs before directories.sh in install.sh)
if id "nasim" &>/dev/null; then
    chown -R nasim:nasim "$BASE_DIR"
else
    echo "Warning: nasim user does not exist on host. Please run security.sh first."
fi

# Set group/owner permissions for Docker service accounts inside volumes
# PostgreSQL runs as UID 70 (postgres)
chown -R 70:70 "$DATA_DIR/postgres" 2>/dev/null || true

# Prometheus runs as UID 65534 (nobody)
chown -R 65534:65534 "$DATA_DIR/prometheus" 2>/dev/null || true

# Grafana runs as UID 472 (grafana)
chown -R 472:472 "$DATA_DIR/grafana" 2>/dev/null || true

# Loki runs as UID 10001 (loki)
chown -R 10001:10001 "$DATA_DIR/loki" 2>/dev/null || true

# Set base access privileges
chmod -R 775 "$BASE_DIR"

echo "Directory hierarchy allocated at $BASE_DIR:"
ls -lh "$BASE_DIR"

echo "===> Release Directories Provisioning Complete!"
