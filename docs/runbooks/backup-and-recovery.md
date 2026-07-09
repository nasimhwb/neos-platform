# NEOS Platform Shared Infrastructure - Backup & Recovery Runbook

This document details the architecture, automated verification, disaster recovery operations, and cloud sync interfaces for the NEOS Platform Backup & Recovery pipeline.

---

## 1. Pipeline Architecture & Specifications

The Backup & Recovery pipeline is designed to be fully automated, cron-safe, and self-validating. It is executed nightly via a system cron job on the host VPS.

### Key Specifications
- **Cron Timing**: Nightly at `02:00 UTC`.
- **Lockfile Location**: `/srv/neos/shared/locks/backup.lock` (Protected via kernel-level `flock` to guarantee zero overlapping runs).
- **Execution Reports Directory**: `/srv/neos/shared/reports/`
- **Latest Execution Report**: `/srv/neos/shared/reports/latest_backup.json`
- **Retention Policy**: `14 days` local retention with automatic cleanup of outdated GPG archives, tarballs, and SHA256 checksums.
- **Alerting Integration**: Alerts are automatically shipped to Alertmanager at `http://alertmanager:9093` for:
  - `BackupLockStale` (when backup lock remains held for > 4 hours).
  - `BackupSystemFailed` (when database, cache, or package creation fails).
  - `BackupOffsiteSyncFailed` (when the offsite sync script returns an error).

---

## 2. Automated & Manual Restore Testing

To guarantee the recoverability of backups, the NEOS Platform includes automated verification loops that simulate full recovery in isolated environments.

### 2.1 Automated Validation Suite
You can trigger a full self-test of the backup system using the master validation engine:
```bash
make validate-backups
```
This command runs `scripts/validate_backups.sh`, which:
1. Triggers a fresh backup (`backups/backup.sh`).
2. Audits the archive's internal structure and checksums (`backups/verify-backup.sh`).
3. Provisions isolated Docker test containers and a test network (`backups/test-restore.sh`) to restore and query database schemas, check Redis cache keys, and probe MinIO health.
4. Generates a markdown validation report in the workspace.

### 2.2 Routine Automated Restore Test
You can run only the restore test on the latest backup archive:
```bash
make test-restore
```
This runs `backups/test-restore.sh`. It is recommended to run this after any major database schema changes or cache engine upgrades.

### 2.3 Manual Database Restorations
In the event of database corruption on a running system:
1. Locate the target backup in `/srv/neos/shared/backups/`.
2. Cleanly restore the databases using the restoration script:
   ```bash
   make restore archive=/srv/neos/shared/backups/neos_backup_YYYY-MM-DD_HHMMSS.tar.gz.gpg
   ```
   *Note: This command will ask for confirmation before dropping existing databases and restoring dumps.*

---

## 3. Offsite Sync & Cloud Recovery

Local backups are synced offsite to cloud storage for disaster recovery.

### 3.1 Offsite Synchronization
Offsite syncing is managed by `backups/offsite_sync.sh`.
- Local SHA256 checksums are calculated.
- The archive is uploaded using rclone.
- A remote integrity check is done using `rclone hash sha256` to compare remote hashes with the local hash. If the provider doesn't support direct hash checks, it falls back to exact size comparisons.
- If verification fails, the corrupted cloud file is unlinked automatically via `rclone delete`.

### 3.2 Offsite Recovery (Bare-Metal VPS Restoration)
If the host VPS experiences complete failure:
1. Provision a clean Ubuntu 24.04 LTS VPS.
2. Clone the repository and initialize the Capistrano directory layout:
   ```bash
   git clone https://github.com/nasimhwb/neos-platform.git /srv/neos-platform
   cd /srv/neos-platform
   make bootstrap
   ```
3. Pull the latest encrypted backup package from offsite storage to `/srv/neos/shared/backups/`.
4. Restore the platform state:
   ```bash
   make restore archive=/srv/neos/shared/backups/neos_backup_YYYY-MM-DD_HHMMSS.tar.gz.gpg
   ```
5. Deploy the docker container stacks:
   ```bash
   make up
   ```

---

## 4. Cloud Provider Decoupled Adapter Interface

To prevent vendor lock-in, the offsite synchronization pipeline uses a decoupled adapter design. The primary interface is `backups/offsite_sync.sh`, which wraps `rclone`.

### 4.1 Interface Specification

Any offsite sync adapter must implement the following contract:
- **Inputs**:
  - Environment variables containing target remote configuration (e.g. `RCLONE_REMOTE_NAME` and `RCLONE_BUCKET_NAME`).
  - Access to the local backup directory containing `neos_backup_*.tar.gz.gpg` (or `.tar.gz`) and the matching `.sha256` checksum files.
- **Behavior**:
  - Locate the latest local backup file.
  - Upload the archive and the `.sha256` file to the remote target.
  - Query the remote target to verify that the uploaded file's SHA256 checksum matches the local file.
  - If a mismatch is detected, delete the corrupted remote file and exit with code `1`.
  - On successful upload and verification, exit with code `0`.

### 4.2 Swapping Cloud Storage Providers (Rclone-Based)
Since `rclone` supports over 40 cloud backends, you can swap providers (e.g., from Backblaze B2 to AWS S3, Cloudflare R2, Wasabi, or Google Cloud Storage) purely through configuration:
1. Configure a new remote using the interactive rclone setup on the VPS:
   ```bash
   rclone config
   ```
2. Update the environment variables in your `.env` file to match the new remote:
   ```env
   RCLONE_REMOTE_NAME=my_new_s3_remote
   RCLONE_BUCKET_NAME=my-neos-backups-bucket
   ```
No code modifications to the backup scripts are required.

### 4.3 Swapping to a Custom Sync Utility (Non-Rclone)
If you want to replace `rclone` entirely with a different command-line utility (e.g., `aws s3` CLI or `azcopy`):
1. Create a new sync script (e.g. `backups/aws_s3_sync.sh`) that satisfies the adapter contract in **Section 4.1**.
2. Update the offsite sync trigger in `backups/backup.sh` (line 230) to call your new script instead of `offsite_sync.sh`:
   ```diff
   - if ! "$SCRIPT_DIR/offsite_sync.sh"; then
   + if ! "$SCRIPT_DIR/aws_s3_sync.sh"; then
   ```
