#!/bin/bash
# ==============================================================================
# NEOS PLATFORM - SHARED INFRASTRUCTURE BACKUP SCRIPT
# ==============================================================================
# This script performs backups of:
#   1. Postgres databases (individually dumped and compressed)
#   2. Redis cache (forces a sync save and copies the dump.rdb)
#   3. MinIO object storage (archives the data volume containing app uploads)
#   4. System configurations (archives configs/ folder)
#   5. SSL Certificates (archives /srv/neos/shared/ssl)

set -e
set -o pipefail

# 1. Load configuration from root environment file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$REPO_DIR/.env"

if [ -f "$ENV_FILE" ]; then
    export $(grep -v '^#' "$ENV_FILE" | xargs)
else
    echo "Error: .env file not found at $ENV_FILE. Cannot run backup."
    exit 1
fi

# Set default backup directory to shared layout
BACKUP_DIR="${BACKUP_DIR:-/srv/neos/shared/backups}"
RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-14}"
TIMESTAMP=$(date +"%Y-%m-%d_%H%M%S")
SESSION_DIR="$BACKUP_DIR/tmp/backup_$TIMESTAMP"

echo "=== Starting Neos Platform Backup: $TIMESTAMP ==="
mkdir -p "$SESSION_DIR"

# ------------------------------------------------------------------------------
# 1. PostgreSQL Database Dumps
# ------------------------------------------------------------------------------
echo "--- Backing up PostgreSQL Databases ---"
if [ -n "${POSTGRES_MULTIPLE_DATABASES:-}" ]; then
    IFS=',' read -ra DB_LIST <<< "$POSTGRES_MULTIPLE_DATABASES"
    for db_entry in "${DB_LIST[@]}"; do
        db_entry=$(echo "$db_entry" | xargs)
        if [ -n "$db_entry" ]; then
            IFS=':' read -ra DB_PARTS <<< "$db_entry"
            db_name="${DB_PARTS[0]}"
            
            echo "Dumping database: $db_name..."
            docker exec -t neos_postgres pg_dump -U "$POSTGRES_SUPERUSER" "$db_name" | gzip > "$SESSION_DIR/postgres_$db_name.sql.gz"
        fi
    done
else
    echo "No databases defined in POSTGRES_MULTIPLE_DATABASES, dumping only main..."
    docker exec -t neos_postgres pg_dump -U "$POSTGRES_SUPERUSER" "$POSTGRES_SUPERUSER" | gzip > "$SESSION_DIR/postgres_main.sql.gz"
fi

# ------------------------------------------------------------------------------
# 2. Redis State Snapshot
# ------------------------------------------------------------------------------
echo "--- Backing up Redis State ---"
echo "Triggering Redis SAVE snapshot..."
docker exec -t neos_redis redis-cli -a "$REDIS_PASSWORD" SAVE || echo "Warning: Redis SAVE command failed. Attempting to copy existing dump.rdb"
docker cp neos_redis:/data/dump.rdb "$SESSION_DIR/redis_dump.rdb"
docker cp neos_redis:/data/appendonlydir "$SESSION_DIR/redis_appendonlydir" 2>/dev/null || true

# ------------------------------------------------------------------------------
# 3. MinIO Object Storage (App Uploads)
# ------------------------------------------------------------------------------
echo "--- Backing up MinIO Object Storage ---"
docker run --rm \
  -v neos_minio_data:/minio_data:ro \
  -v "$SESSION_DIR":/backup_dest \
  alpine tar -czf /backup_dest/minio_data.tar.gz -C /minio_data .

# ------------------------------------------------------------------------------
# 4. System Configurations Backup
# ------------------------------------------------------------------------------
echo "--- Backing up System Configurations ---"
if [ -d "$REPO_DIR/configs" ]; then
    tar -czf "$SESSION_DIR/configs.tar.gz" -C "$REPO_DIR" configs
else
    echo "Warning: configs directory not found at $REPO_DIR/configs."
fi

# ------------------------------------------------------------------------------
# 5. SSL Certificates Backup
# ------------------------------------------------------------------------------
echo "--- Backing up SSL Certificates ---"
if [ -d "/srv/neos/shared/ssl" ]; then
    tar -czf "$SESSION_DIR/ssl_certs.tar.gz" -C "/srv/neos/shared" ssl
else
    echo "Warning: SSL certs path '/srv/neos/shared/ssl' not found. Skipping SSL backup."
fi

# ------------------------------------------------------------------------------
# 6. Packaging and Compressing Backup Session
# ------------------------------------------------------------------------------
echo "--- Packaging and Compressing Backup ---"
BACKUP_ARCHIVE="$BACKUP_DIR/neos_backup_$TIMESTAMP.tar.gz"
tar -czf "$BACKUP_ARCHIVE" -C "$BACKUP_DIR/tmp" "backup_$TIMESTAMP"

# Clean up temp session files
rm -rf "$SESSION_DIR"
rm -rf "$BACKUP_DIR/tmp"

echo "Backup archive created: $BACKUP_ARCHIVE"

# ------------------------------------------------------------------------------
# 7. Enforce Retention Policy
# ------------------------------------------------------------------------------
echo "--- Cleaning up backups older than $RETENTION_DAYS days ---"
find "$BACKUP_DIR" -name "neos_backup_*.tar.gz" -type f -mtime +"$RETENTION_DAYS" -exec rm -v {} \;

# ------------------------------------------------------------------------------
# 8. Offsite Cloud Backup (rclone Integration Placeholder)
# ------------------------------------------------------------------------------
# echo "--- Uploading to Cloud Storage (rclone) ---"
# if command -v rclone &> /dev/null; then
#     rclone copy "$BACKUP_ARCHIVE" "$RCLONE_REMOTE_NAME:$RCLONE_BUCKET_NAME/"
#     echo "Cloud sync completed successfully."
# else
#     echo "Warning: rclone is not installed. Skipping offsite cloud upload."
# fi

echo "=== Backup Completed Successfully at $(date) ==="
