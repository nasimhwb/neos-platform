#!/bin/bash
# ==============================================================================
# NEOS PLATFORM - BACKUP INTEGRITY VERIFICATION TOOL
# ==============================================================================
# Finds the latest backup file (encrypted or not), checks checksums, decrypts
# it, and audits all contained database, cache, storage, and config assets.
#
# Usage: ./verify-backup.sh [path_to_backup_archive.tar.gz[.gpg]]

set -e
set -o pipefail

BACKUP_DIR="/srv/neos/shared/backups"
TARGET_ARCHIVE=""

# 1. Determine target archive
if [ $# -eq 1 ]; then
    TARGET_ARCHIVE="$1"
else
    echo "No backup archive specified. Searching for latest backup in $BACKUP_DIR..."
    # Search for latest .gpg or .tar.gz
    TARGET_ARCHIVE=$(ls -1t "$BACKUP_DIR"/neos_backup_* 2>/dev/null | grep -E '\.(tar\.gz|gpg)$' | head -n 1 || true)
fi

if [ -z "$TARGET_ARCHIVE" ] || [ ! -f "$TARGET_ARCHIVE" ]; then
    echo "ERROR: No backup archive file found to verify."
    exit 1
fi

echo "=========================================================================="
echo "Verifying backup archive: $TARGET_ARCHIVE"
echo "File Size: $(du -sh "$TARGET_ARCHIVE" | awk '{print $1}')"
echo "=========================================================================="

# 2. Verify SHA256 Checksum
CHECKSUM_FILE="$TARGET_ARCHIVE.sha256"
if [ -f "$CHECKSUM_FILE" ]; then
    echo "0. Verifying SHA256 integrity checksum..."
    # Read the expected checksum from the file and verify it on the target archive
    expected_sum=$(awk '{print $1}' "$CHECKSUM_FILE")
    computed_sum=$(sha256sum "$TARGET_ARCHIVE" | awk '{print $1}')
    if [ "$expected_sum" != "$computed_sum" ]; then
        echo ">>> ERROR: SHA256 checksum MISMATCH!"
        echo "    Expected: $expected_sum"
        echo "    Computed: $computed_sum"
        exit 1
    fi
    echo "   [PASS] SHA256 checksum is valid."
else
    echo "   [WARN] No SHA256 checksum file (.sha256) found. Skipping checksum verification."
fi

# 3. Create temp workspace for inspection
TEMP_WORK_DIR="/tmp/verify_backup_$(date +%s)"
mkdir -p "$TEMP_WORK_DIR"

DECRYPTED_ARCHIVE=""
cleanup_verify() {
    echo "Cleaning up verify temporary files..."
    rm -rf "$TEMP_WORK_DIR"
    if [ -n "$DECRYPTED_ARCHIVE" ] && [ -f "$DECRYPTED_ARCHIVE" ]; then
        rm -f "$DECRYPTED_ARCHIVE"
    fi
}
trap cleanup_verify EXIT

# 4. Decrypt if GPG
if [[ "$TARGET_ARCHIVE" == *.gpg ]]; then
    echo "1. Deciphering encrypted GPG backup package..."
    if [ -z "${BACKUP_PASSPHRASE:-}" ]; then
        # Load env file to see if we can read the passphrase
        SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        ENV_FILE="$(dirname "$SCRIPT_DIR")/.env"
        if [ -f "$ENV_FILE" ]; then
            export $(grep -v '^#' "$ENV_FILE" | xargs)
        fi
    fi
    
    if [ -z "${BACKUP_PASSPHRASE:-}" ]; then
        echo "ERROR: BACKUP_PASSPHRASE environment variable is not defined. Cannot decrypt."
        exit 1
    fi
    
    DECRYPTED_ARCHIVE="$TEMP_WORK_DIR/decrypted_verify_neos_backup.tar.gz"
    gpg --decrypt --batch --yes --passphrase "$BACKUP_PASSPHRASE" --output "$DECRYPTED_ARCHIVE" "$TARGET_ARCHIVE"
    TARGET_ARCHIVE="$DECRYPTED_ARCHIVE"
fi

# 5. Check tar integrity
echo "2. Checking archive compression structural integrity..."
if ! tar -tzf "$TARGET_ARCHIVE" &>/dev/null; then
    echo ">>> ERROR: Backup archive is corrupted or invalid."
    exit 1
fi
echo "   [PASS] Archive is structurally valid."

# Extract archive
echo "3. Unpacking archive contents to workspace..."
tar -xzf "$TARGET_ARCHIVE" -C "$TEMP_WORK_DIR"

# Get inside the session directory name
SESSION_DIR=$(find "$TEMP_WORK_DIR" -maxdepth 1 -type d -name "backup_*" | head -n 1)

if [ -z "$SESSION_DIR" ]; then
    echo ">>> ERROR: Extracted contents are missing standard 'backup_YYYY-MM-DD_HHMMSS' session root."
    exit 1
fi

# 6. Verify presence of required assets
echo "4. Auditing nested components..."

FAILED=0

# Verify Postgres Dumps
PG_DUMPS=$(find "$SESSION_DIR" -name "postgres_*.sql.gz" | wc -l)
if [ "$PG_DUMPS" -eq 0 ]; then
    echo "   [FAIL] PostgreSQL database dumps are missing!"
    FAILED=1
else
    echo "   [PASS] PostgreSQL database dumps: $PG_DUMPS file(s) found."
fi

# Verify Redis Snapshot (RDB)
if [ ! -f "$SESSION_DIR/redis_dump.rdb" ]; then
    echo "   [FAIL] Redis cache 'redis_dump.rdb' is missing!"
    FAILED=1
else
    echo "   [PASS] Redis state 'redis_dump.rdb' found."
fi

# Verify Redis Journaling (AOF)
if [ ! -d "$SESSION_DIR/redis_appendonlydir" ]; then
    echo "   [WARN] Redis journaling 'redis_appendonlydir' is missing (AOF was disabled or empty)."
else
    echo "   [PASS] Redis journaling 'redis_appendonlydir' found."
fi

# Verify MinIO Storage Tarball
if [ ! -f "$SESSION_DIR/minio_data.tar.gz" ]; then
    echo "   [FAIL] MinIO object storage 'minio_data.tar.gz' is missing!"
    FAILED=1
else
    echo "   [PASS] MinIO object storage 'minio_data.tar.gz' found."
fi

# Verify Configuration files
if [ ! -f "$SESSION_DIR/configs.tar.gz" ]; then
    echo "   [FAIL] Repository configurations 'configs.tar.gz' is missing!"
    FAILED=1
else
    echo "   [PASS] Repository configurations 'configs.tar.gz' found."
fi

# Verify SSL Certificates
if [ ! -f "$SESSION_DIR/ssl_certs.tar.gz" ]; then
    echo "   [WARN] SSL certificates 'ssl_certs.tar.gz' is missing."
else
    echo "   [PASS] SSL certificates 'ssl_certs.tar.gz' found."
fi

# 7. Output Verification report
echo "=========================================================================="
if [ "$FAILED" -eq 1 ]; then
    echo ">>> [FAILURE] Backup verification failed. Some critical assets are missing."
    exit 1
else
    echo ">>> [SUCCESS] Backup integrity and structure successfully verified!"
    echo "    Archive is ready and complete for recovery operations."
fi
echo "=========================================================================="
