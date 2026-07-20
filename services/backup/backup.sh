#!/bin/bash
# ==============================================================================
# NEOS PLATFORM - ENTERPRISE BACKUP ENGINE
# ==============================================================================
# Performs secure, encrypted backups of:
#   1. PostgreSQL Databases (individual dumps)
#   2. Redis State Snapshot (RDB and AOF journals)
#   3. MinIO Object Storage (user application uploads)
#   4. Shared System Configuration Files
#   5. SSL Certificates
#
# Encrypts the final package using GnuPG and computes SHA256 integrity checksums.
# Reports any failures automatically to Alertmanager.

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

# ------------------------------------------------------------------------------
# Failure Notification Hook (Alertmanager Integration)
# ------------------------------------------------------------------------------
send_failure_alert() {
    local exit_code=$1
    local line_num=$2
    if [ "$exit_code" -ne 0 ]; then
        echo ">>> ERROR: Backup job failed at line $line_num with exit code $exit_code."
        echo "Sending critical alert to Alertmanager..."
        
        curl -s -X POST -H "Content-Type: application/json" \
          -d "[{
            \"labels\": {
              \"alertname\": \"BackupSystemFailed\",
              \"severity\": \"critical\",
              \"instance\": \"host-vps\"
            },
            \"annotations\": {
              \"summary\": \"NEOS Platform Backup Job Failed\",
              \"description\": \"Backup execution script terminated abnormally on line $line_num. Status: $exit_code.\"
            }
          }]" \
          http://alertmanager:9093/api/v2/alerts || echo "Warning: Failed to contact Alertmanager."
    fi
}
# Trap all errors to alert handler
trap 'send_failure_alert $? $LINENO' ERR

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
            docker exec neos_postgres pg_dump -U "$POSTGRES_SUPERUSER" "$db_name" | gzip > "$SESSION_DIR/postgres_$db_name.sql.gz"
        fi
    done
else
    echo "No databases defined in POSTGRES_MULTIPLE_DATABASES, dumping only main..."
    docker exec neos_postgres pg_dump -U "$POSTGRES_SUPERUSER" "$POSTGRES_SUPERUSER" | gzip > "$SESSION_DIR/postgres_main.sql.gz"
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

# ------------------------------------------------------------------------------
# 7. Encryption & Integrity Checksums
# ------------------------------------------------------------------------------
if [ -n "${BACKUP_PASSPHRASE:-}" ]; then
    echo "--- Encrypting Backup Package ---"
    # Encrypt symmetrically using GPG
    gpg --symmetric --batch --yes --passphrase "$BACKUP_PASSPHRASE" --output "$BACKUP_ARCHIVE.gpg" "$BACKUP_ARCHIVE"
    
    # Compute SHA256 checksum on the encrypted package
    (cd "$BACKUP_DIR" && sha256sum "neos_backup_$TIMESTAMP.tar.gz.gpg" > "neos_backup_$TIMESTAMP.tar.gz.gpg.sha256")
    
    # Remove the unencrypted archive
    rm -f "$BACKUP_ARCHIVE"
    echo "Encrypted backup created: $BACKUP_ARCHIVE.gpg"
    echo "Checksum created: $BACKUP_ARCHIVE.gpg.sha256"
else
    # Compute SHA256 checksum on the raw package
    (cd "$BACKUP_DIR" && sha256sum "neos_backup_$TIMESTAMP.tar.gz" > "neos_backup_$TIMESTAMP.tar.gz.sha256")
    echo "Warning: BACKUP_PASSPHRASE is not set. Backup is not encrypted."
    echo "Checksum created: $BACKUP_ARCHIVE.sha256"
fi

# ------------------------------------------------------------------------------
# 8. Enforce Retention Policy
# ------------------------------------------------------------------------------
echo "--- Cleaning up backups older than $RETENTION_DAYS days ---"
# Prune old GPG, TAR, and SHA256 files
find "$BACKUP_DIR" -name "neos_backup_*" -type f -mtime +"$RETENTION_DAYS" -exec rm -v {} \;

echo "=== Backup Completed Successfully at $(date) ==="
