#!/bin/bash
# ==============================================================================
# NEOS PLATFORM - OFFSITE BACKUP SYNC ENGINE
# ==============================================================================
# Decoupled synchronization engine utilizing rclone provider abstractions.
# Supports sync to: Cloudflare R2, Backblaze B2, Wasabi, AWS S3, Google Cloud Storage,
# Azure Blob, Synology NAS, or any custom WebDAV / SFTP endpoints.

set -eu
set -o pipefail

# ANSI color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 1. Load Configurations
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$REPO_DIR/.env"

if [ -f "$ENV_FILE" ]; then
    export $(grep -v '^#' "$ENV_FILE" | xargs)
else
    echo "ERROR: Environment file not found at $ENV_FILE."
    exit 1
fi

LOCAL_BACKUP_DIR="${BACKUP_DIR:-/srv/neos/shared/backups}"
REMOTE_NAME="${RCLONE_REMOTE_NAME:-}"
BUCKET_NAME="${RCLONE_BUCKET_NAME:-}"
MAX_RETRIES=3

echo -e "${BLUE}==========================================================================${NC}"
echo -e "${BLUE}=== Starting Offsite Backup Synchronization ===${NC}"
echo -e "${BLUE}==========================================================================${NC}"

# Check if offsite sync is configured
if [ -z "$REMOTE_NAME" ] || [ -z "$BUCKET_NAME" ]; then
    echo -e "${YELLOW}Warning: RCLONE_REMOTE_NAME or RCLONE_BUCKET_NAME is not defined.${NC}"
    echo "Skipping offsite sync. Local-only backups will be retained."
    exit 0
fi

# Locate latest backup file
LATEST_BACKUP=$(ls -1t "$LOCAL_BACKUP_DIR"/neos_backup_* 2>/dev/null | grep -E '\.(tar\.gz|gpg)$' | head -n 1 || true)
if [ -z "$LATEST_BACKUP" ]; then
    echo -e "${RED}ERROR: No local backup files found in $LOCAL_BACKUP_DIR to sync.${NC}"
    exit 1
fi

BACKUP_FILENAME=$(basename "$LATEST_BACKUP")
CHECKSUM_FILENAME="$BACKUP_FILENAME.sha256"

# Check if rclone is installed
if ! command -v rclone &>/dev/null; then
    echo -e "${RED}ERROR: rclone tool is not installed on the host VPS.${NC}"
    exit 1
fi

# Sync Function with Retry Loop
sync_file() {
    local file_path=$1
    local dest_target=$2
    local attempt=1
    
    echo "Uploading $(basename "$file_path") to $dest_target..."
    
    while [ $attempt -le $MAX_RETRIES ]; do
        echo "  Attempt $attempt of $MAX_RETRIES..."
        if rclone copy "$file_path" "$dest_target" --progress; then
            echo -e "  ${GREEN}[PASS] Upload completed successfully.${NC}"
            return 0
        fi
        echo -e "  ${YELLOW}Warning: Upload failed. Retrying in 10s...${NC}"
        sleep 10
        attempt=$((attempt + 1))
    done
    return 1
}

# Sync Backup Package
sync_file "$LATEST_BACKUP" "$REMOTE_NAME:$BUCKET_NAME" || { echo "ERROR: Failed to upload backup package."; exit 1; }

# Sync SHA256 Checksum File
if [ -f "$LOCAL_BACKUP_DIR/$CHECKSUM_FILENAME" ]; then
    sync_file "$LOCAL_BACKUP_DIR/$CHECKSUM_FILENAME" "$REMOTE_NAME:$BUCKET_NAME" || { echo "ERROR: Failed to upload checksum file."; exit 1; }
fi

# 2. Post-Upload Checksum Integrity Verification
echo "Verifying remote checksum integrity..."
LOCAL_SUM=$(sha256sum "$LATEST_BACKUP" | awk '{print $1}')

# Check remote SHA256 hash using rclone hash
REMOTE_SUM=$(rclone hash sha256 "$REMOTE_NAME:$BUCKET_NAME/$BACKUP_FILENAME" 2>/dev/null | awk '{print $1}' || echo "")

if [ -n "$REMOTE_SUM" ] && [ "$REMOTE_SUM" != "-" ]; then
    if [ "$REMOTE_SUM" = "$LOCAL_SUM" ]; then
        echo -e "${GREEN}[PASS] Remote SHA256 checksum matches local hash: $REMOTE_SUM${NC}"
    else
        echo -e "${RED}ERROR: Remote checksum mismatch! Local: $LOCAL_SUM, Remote: $REMOTE_SUM${NC}"
        # Cleanup failed upload
        echo "Cleaning up invalid remote upload..."
        rclone delete "$REMOTE_NAME:$BUCKET_NAME/$BACKUP_FILENAME" || true
        exit 1
    fi
else
    echo -e "${YELLOW}Warning: Remote provider does not support direct SHA256 checksum query. Falling back to size checks.${NC}"
fi

# Fetch remote size/hash if supported by remote provider
REMOTE_SIZE=$(rclone size "$REMOTE_NAME:$BUCKET_NAME/$BACKUP_FILENAME" --json | grep -oP '"bytes":\s*\K\d+' || echo "0")
LOCAL_SIZE=$(stat -c %s "$LATEST_BACKUP")

if [ "$REMOTE_SIZE" -eq "$LOCAL_SIZE" ]; then
    echo -e "${GREEN}[PASS] Remote file size ($REMOTE_SIZE bytes) matches local file size.${NC}"
else
    echo -e "${RED}ERROR: Size mismatch! Local: $LOCAL_SIZE bytes, Remote: $REMOTE_SIZE bytes.${NC}"
    # Cleanup failed upload
    echo "Cleaning up invalid remote upload..."
    rclone delete "$REMOTE_NAME:$BUCKET_NAME/$BACKUP_FILENAME" || true
    exit 1
fi

echo -e "${GREEN}==========================================================================${NC}"
echo -e "${GREEN}=== [SUCCESS] Offsite backup sync successfully verified! ===${NC}"
echo -e "${GREEN}==========================================================================${NC}"
exit 0
