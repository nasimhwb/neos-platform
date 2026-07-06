#!/bin/bash
# ==============================================================================
# NEOS PLATFORM - SHARED INFRASTRUCTURE BACKUP SCRIPT
# ==============================================================================
# This script performs backups of:
#   1. Postgres databases (each database dumped individually for modular restore)
#   2. Redis cache (forces a sync save and copies the dump.rdb)
#   3. MinIO object storage (archives the data volume)
#
# Configure this script via cron for automated backups (e.g., daily at 2:00 AM).

set -e
set -o pipefail

# 1. Load configuration from root environment file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$REPO_DIR/.env"

if [ -f "$ENV_FILE" ]; then
    # Load environment variables, ignoring comments
    export $(grep -v '^#' "$ENV_FILE" | xargs)
else
    echo "Error: .env file not found at $ENV_FILE. Cannot run backup."
    exit 1
fi

# Set default backup directory if not specified
BACKUP_DIR="${BACKUP_DIR:-/srv/neos/backups}"
RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-14}"
TIMESTAMP=$(date +"%Y-%m-%d_%H%M%S")
SESSION_DIR="$BACKUP_DIR/tmp/backup_$TIMESTAMP"

echo "=== Starting Neos Platform Backup: $TIMESTAMP ==="
mkdir -p "$SESSION_DIR"

# ------------------------------------------------------------------------------
# 1. PostgreSQL Individual Database Dumps
# ------------------------------------------------------------------------------
echo "--- Backing up PostgreSQL Databases ---"
if [ -n "${POSTGRES_MULTIPLE_DATABASES:-}" ]; then
    # Split by comma
    IFS=',' read -ra DB_LIST <<< "$POSTGRES_MULTIPLE_DATABASES"
    for db_entry in "${DB_LIST[@]}"; do
        db_entry=$(echo "$db_entry" | xargs)
        if [ -n "$db_entry" ]; then
            IFS=':' read -ra DB_PARTS <<< "$db_entry"
            db_name="${DB_PARTS[0]}"
            
            echo "Dumping database: $db_name..."
            # Execute pg_dump inside the container and compress it on the host
            docker exec -t neos_postgres pg_dump -U "$POSTGRES_SUPERUSER" "$db_name" | gzip > "$SESSION_DIR/postgres_$db_name.sql.gz"
        fi
    done
else
    echo "No databases defined in POSTGRES_MULTIPLE_DATABASES, dumping only main '$POSTGRES_SUPERUSER' database..."
    docker exec -t neos_postgres pg_dump -U "$POSTGRES_SUPERUSER" "$POSTGRES_SUPERUSER" | gzip > "$SESSION_DIR/postgres_main.sql.gz"
fi

# ------------------------------------------------------------------------------
# 2. Redis State Snapshot
# ------------------------------------------------------------------------------
echo "--- Backing up Redis State ---"
# Trigger a synchronous SAVE to disk inside Redis
echo "Triggering Redis SAVE snapshot..."
docker exec -t neos_redis redis-cli -a "$REDIS_PASSWORD" SAVE || echo "Warning: Redis SAVE command failed. Attempting to copy existing dump.rdb"

# Copy the dump.rdb from the Docker volume
# Since named volumes are stored in /var/lib/docker/volumes/ on host,
# we can use docker cp to safely extract it from the running container.
docker cp neos_redis:/data/dump.rdb "$SESSION_DIR/redis_dump.rdb"

# ------------------------------------------------------------------------------
# 3. MinIO Object Storage Archive
# ------------------------------------------------------------------------------
echo "--- Backing up MinIO Object Storage ---"
# Archive the MinIO data from the named volume via a helper container
# This is cleaner than accessing host paths directly and handles volume structures safely.
docker run --rm \
  -v neos_minio_data:/minio_data:ro \
  -v "$SESSION_DIR":/backup_dest \
  alpine tar -czf /backup_dest/minio_data.tar.gz -C /minio_data .

# ------------------------------------------------------------------------------
# 4. Packaging and Compressing Backup Session
# ------------------------------------------------------------------------------
echo "--- Packaging and Compressing Backup ---"
BACKUP_ARCHIVE="$BACKUP_DIR/neos_backup_$TIMESTAMP.tar.gz"
tar -czf "$BACKUP_ARCHIVE" -C "$BACKUP_DIR/tmp" "backup_$TIMESTAMP"

# Clean up temp session files
rm -rf "$SESSION_DIR"
rm -rf "$BACKUP_DIR/tmp"

echo "Backup archive created: $BACKUP_ARCHIVE"

# ------------------------------------------------------------------------------
# 5. Enforce Retention Policy (Delete old backups)
# ------------------------------------------------------------------------------
echo "--- Cleaning up backups older than $RETENTION_DAYS days ---"
find "$BACKUP_DIR" -name "neos_backup_*.tar.gz" -type f -mtime +"$RETENTION_DAYS" -exec rm -v {} \;

# ------------------------------------------------------------------------------
# 6. Offsite Cloud Backup (rclone Integration Placeholder)
# ------------------------------------------------------------------------------
# Set up rclone on the VPS (rclone config) and define the remote:
# example: rclone config create b2-backups b2 account ...
#
# If configured, uncomment the lines below to sync backups to cloud storage:
#
# echo "--- Uploading to Cloud Storage (rclone) ---"
# if command -v rclone &> /dev/null; then
#     rclone copy "$BACKUP_ARCHIVE" "$RCLONE_REMOTE_NAME:$RCLONE_BUCKET_NAME/"
#     echo "Cloud sync completed successfully."
# else
#     echo "Warning: rclone is not installed. Skipping offsite cloud upload."
# fi

echo "=== Backup Completed Successfully at $(date) ==="
