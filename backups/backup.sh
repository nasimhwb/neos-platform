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

START_TIME=$(date -uIs)
LOCKFILE="/srv/neos/shared/locks/backup.lock"
mkdir -p "$(dirname "$LOCKFILE")"

# Open the lockfile on file descriptor 9
exec 9>"$LOCKFILE"

# Try to acquire an exclusive lock
if ! flock -n 9; then
    # Lock is held by another process. Check lock file age to alert if stale.
    if [ -f "$LOCKFILE" ]; then
        LOCK_AGE=$(( $(date +%s) - $(stat -c %Y "$LOCKFILE" 2>/dev/null || date +%s) ))
        if [ "$LOCK_AGE" -gt 14400 ]; then
            echo "Warning: Stale lock detected (age: ${LOCK_AGE}s > 4 hours). Sending stale lock notification..."
            curl -s -X POST -H "Content-Type: application/json" \
              -d "[{
                \"labels\": {
                  \"alertname\": \"BackupLockStale\",
                  \"severity\": \"warning\",
                  \"instance\": \"host-vps\"
                },
                \"annotations\": {
                  \"summary\": \"Backup lockfile has persisted too long\",
                  \"description\": \"The backup lockfile has been held for more than 4 hours (age: ${LOCK_AGE}s). Investigation is required.\"
                }
              }]" \
              http://alertmanager:9093/api/v2/alerts || true
        fi
    fi
    echo "ERROR: Backup job is already running. Aborting."
    exit 1
fi

# Write the current process ID into the lockfile
echo $$ >&9

cleanup_lock() {
    # Close file descriptor 9 to release the lock, then remove the lock file.
    exec 9>&-
    rm -f "$LOCKFILE"
}
trap cleanup_lock EXIT

# 1. Load configuration from root environment file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$REPO_DIR/.env"

if [ -f "$ENV_FILE" ]; then
    set -a
    source <(tr -d '\r' < "$ENV_FILE")
    set +a
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
        
        # Write SRE JSON report
        END_TIME=$(date -uIs)
        mkdir -p "/srv/neos/shared/reports"
        cat <<EOF > "/srv/neos/shared/reports/latest_backup.json"
{
  "start_time": "$START_TIME",
  "end_time": "$END_TIME",
  "duration_seconds": 0,
  "status": "failed",
  "file_size_bytes": 0,
  "checksum": "",
  "checksum_status": "none",
  "encrypted": false,
  "offsite_sync_status": "skipped",
  "error": "Script terminated on line $line_num with exit code $exit_code"
}
EOF

        # Safe cleanup path for partial files
        echo "Cleaning up partial backup files..."
        rm -rf "${SESSION_DIR:-}"
        rm -rf "$BACKUP_DIR/tmp"

        # Check if it was a command timeout (exit code 124)
        local alert_name="BackupSystemFailed"
        local alert_desc="Backup execution script terminated abnormally on line $line_num. Status: $exit_code."
        if [ "$exit_code" -eq 124 ]; then
            alert_name="BackupTimeout"
            alert_desc="Backup execution timed out on line $line_num (exceeded command timeout limit)."
        fi

        echo "Sending critical alert to Alertmanager ($alert_name)..."
        curl -s -X POST -H "Content-Type: application/json" \
          -d "[{
            \"labels\": {
              \"alertname\": \"$alert_name\",
              \"severity\": \"critical\",
              \"instance\": \"host-vps\"
            },
            \"annotations\": {
              \"summary\": \"NEOS Platform Backup Job Failed\",
              \"description\": \"$alert_desc\"
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
            timeout 180s docker exec neos_postgres pg_dump -U "$POSTGRES_SUPERUSER" "$db_name" | gzip > "$SESSION_DIR/postgres_$db_name.sql.gz"
        fi
    done
else
    echo "No databases defined in POSTGRES_MULTIPLE_DATABASES, dumping only main..."
    timeout 180s docker exec neos_postgres pg_dump -U "$POSTGRES_SUPERUSER" "$POSTGRES_SUPERUSER" | gzip > "$SESSION_DIR/postgres_main.sql.gz"
fi

# ------------------------------------------------------------------------------
# 2. Redis State Snapshot
# ------------------------------------------------------------------------------
echo "--- Backing up Redis State ---"
echo "Triggering Redis SAVE snapshot..."
timeout 60s docker exec -t neos_redis redis-cli -a "$REDIS_PASSWORD" SAVE || echo "Warning: Redis SAVE command failed. Attempting to copy existing dump.rdb"
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
echo "--- Cleaning up backups older than $RETENTION_DAYS days ---"
# Prune old GPG, TAR, and SHA256 files
find "$BACKUP_DIR" -name "neos_backup_*" -type f -mtime +"$RETENTION_DAYS" -exec rm -v {} \;

# 9. Trigger Offsite Backup Synchronization
echo "--- Triggering Offsite Backup Sync ---"
chmod +x "$SCRIPT_DIR/offsite_sync.sh"
OFFSITE_STATUS="success"

if ! "$SCRIPT_DIR/offsite_sync.sh"; then
    echo "Warning: Offsite backup sync failed."
    OFFSITE_STATUS="failed"
    # Send alert to Alertmanager
    curl -s -X POST -H "Content-Type: application/json" \
      -d "[{
        \"labels\": {
          \"alertname\": \"BackupOffsiteSyncFailed\",
          \"severity\": \"critical\",
          \"instance\": \"host-vps\"
        },
        \"annotations\": {
          \"summary\": \"Backup offsite upload failed\",
          \"description\": \"Backup was packaged locally, but pushing to the offsite target returned a failure code.\"
        }
      }]" \
      http://alertmanager:9093/api/v2/alerts || true
fi

# 10. Generate SRE Execution Report
END_TIME=$(date -uIs)
# Handle date conversion compatibility on macOS vs Linux
if date -d "$START_TIME" +%s &>/dev/null; then
    START_SEC=$(date -d "$START_TIME" +%s)
    END_SEC=$(date -d "$END_TIME" +%s)
else
    START_SEC=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${START_TIME%Z}" +%s 2>/dev/null || echo "0")
    END_SEC=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${END_TIME%Z}" +%s 2>/dev/null || echo "0")
fi
DURATION=$(( END_SEC - START_SEC ))
if [ $DURATION -lt 0 ]; then DURATION=0; fi

FILE_SIZE=0
if [ -f "${BACKUP_ARCHIVE}.gpg" ]; then
    FILE_SIZE=$(stat -c %s "${BACKUP_ARCHIVE}.gpg" 2>/dev/null || stat -f %z "${BACKUP_ARCHIVE}.gpg" 2>/dev/null || echo "0")
elif [ -f "$BACKUP_ARCHIVE" ]; then
    FILE_SIZE=$(stat -c %s "$BACKUP_ARCHIVE" 2>/dev/null || stat -f %z "$BACKUP_ARCHIVE" 2>/dev/null || echo "0")
fi

CHECKSUM=""
if [ -f "${BACKUP_ARCHIVE}.gpg.sha256" ]; then
    CHECKSUM=$(cat "${BACKUP_ARCHIVE}.gpg.sha256" 2>/dev/null | awk '{print $1}')
elif [ -f "${BACKUP_ARCHIVE}.sha256" ]; then
    CHECKSUM=$(cat "${BACKUP_ARCHIVE}.sha256" 2>/dev/null | awk '{print $1}')
fi

# Determine checksum status
CHECKSUM_STATUS="verified"
if [ "$OFFSITE_STATUS" = "skipped" ]; then
    CHECKSUM_STATUS="generated"
elif [ "$OFFSITE_STATUS" = "failed" ]; then
    CHECKSUM_STATUS="failed"
fi

mkdir -p "/srv/neos/shared/reports"
cat <<EOF > "/srv/neos/shared/reports/latest_backup.json"
{
  "start_time": "$START_TIME",
  "end_time": "$END_TIME",
  "duration_seconds": $DURATION,
  "status": "success",
  "file_size_bytes": $FILE_SIZE,
  "checksum": "$CHECKSUM",
  "checksum_status": "$CHECKSUM_STATUS",
  "encrypted": $([ -n "${BACKUP_PASSPHRASE:-}" ] && echo "true" || echo "false"),
  "offsite_sync_status": "$OFFSITE_STATUS"
}
EOF

echo "=== Backup Completed Successfully at $(date) ==="
