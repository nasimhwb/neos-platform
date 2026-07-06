#!/bin/bash
# ==============================================================================
# NEOS PLATFORM BOOTSTRAP - HOST DIRECTORIES INITIALIZATION
# ==============================================================================
set -e

echo "===> [3/6] Initializing Host Directory Hierarchy..."

# Define base paths
BASE_DIR="/srv/neos"
DATA_DIR="$BASE_DIR/data"
BACKUP_DIR="$BASE_DIR/backups"
PROXY_DIR="$BASE_DIR/letsencrypt"
WWW_DIR="$BASE_DIR/www"

# 1. Create Base Directories
echo "Creating root paths at $BASE_DIR..."
mkdir -p "$BASE_DIR"
mkdir -p "$WWW_DIR"
mkdir -p "$PROXY_DIR"
mkdir -p "$BACKUP_DIR"
mkdir -p "$BACKUP_DIR/tmp"

# 2. Create Service Persistent Volumes
echo "Creating storage paths for databases and monitoring services..."
mkdir -p "$DATA_DIR/postgres"
mkdir -p "$DATA_DIR/redis"
mkdir -p "$DATA_DIR/minio"
mkdir -p "$DATA_DIR/prometheus"
mkdir -p "$DATA_DIR/grafana"
mkdir -p "$DATA_DIR/loki"
mkdir -p "$DATA_DIR/portainer"
mkdir -p "$DATA_DIR/uptime-kuma"

# 3. Set Permissions
# Grant read/write access to Docker containers mapping user IDs where needed.
echo "Setting secure permissions on directory trees..."
chmod -R 755 "$BASE_DIR"

# PostgreSQL Alpine image usually runs as UID 70 (postgres)
chown -R 70:70 "$DATA_DIR/postgres" 2>/dev/null || true

# Prometheus runs as UID 65534 (nobody)
chown -R 65534:65534 "$DATA_DIR/prometheus" 2>/dev/null || true

# Grafana runs as UID 472 (grafana)
chown -R 472:472 "$DATA_DIR/grafana" 2>/dev/null || true

# Loki runs as UID 10001 (loki)
chown -R 10001:10001 "$DATA_DIR/loki" 2>/dev/null || true

echo "Host Directory Hierarchy successfully configured:"
find "$BASE_DIR" -maxdepth 3 -type d

echo "===> Host Directories Initialization Complete!"
