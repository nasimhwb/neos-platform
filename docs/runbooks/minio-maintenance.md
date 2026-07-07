# MinIO Object Storage Platform Runbook

This document describes the operational maintenance, IAM policies, object lifecycle rules, backup routines, and recovery procedures for the NEOS Platform MinIO S3-compatible storage.

---

## 1. Bucket and User Topology

MinIO is configured automatically via the `minio-init` sidecar container. The default layout consists of:

| Bucket Name | Target User | Custom Policy | Purpose |
| :--- | :--- | :--- | :--- |
| **`neos-erp`** | `erp_user` | `neos-erp-rw` | ERP uploads (attachments, reports) |
| **`neos-inventory`** | `inventory_user` | `neos-inventory-rw` | Inventory photos and documents |
| **`neos-ai-services`** | `ai_user` | `neos-ai-services-rw` | AI dataset training logs and outputs |
| **`supabase-storage`** | `supabase_user` | `supabase-storage-rw` | Target backend for Supabase Storage API |

### IAM Read-Write Policy Template
Each app user is bound to a specific policy preventing access to other buckets:
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": ["s3:*"],
            "Resource": [
                "arn:aws:s3:::<bucket_name>",
                "arn:aws:s3:::<bucket_name>/*"
            ]
        }
    ]
}
```

---

## 2. Object Lifecycle Policies (ILM)

To prevent storage bloat on the VPS node, we set up Object Lifecycle Management (ILM) rules:
* **Rule**: Expire all objects matching the prefix `tmp/` inside any bucket after **30 days**.
* **Automatic Enforcement**: Handled natively by the MinIO engine after rules registration by the init container.

To audit or change lifecycle rules manually:
1. Alias the admin client:
   ```bash
   mc alias set local http://localhost:9000 admin_username admin_password
   ```
2. List active ILM rules for a bucket:
   ```bash
   mc ilm rule list local/neos-erp
   ```
3. Add a rule to transition older files to cold storage (placeholder logic):
   ```bash
   mc ilm rule add --transition-days 90 --storage-class "COLD" local/neos-erp
   ```

---

## 3. Backups & Restore Testing

### Backup Strategy
MinIO persistent data resides inside the named volume `neos_minio_data` which points to `/srv/neos/shared/data/minio/`.
* **Backup execution**: `make backup` runs `backups/backup.sh`, archiving the contents of `neos_minio_data` into `/srv/neos/shared/backups/neos_backup_*.tar.gz` using an Alpine helper container.
* **Integrity check**: `make verify-backup` unpacks and confirms that `minio_data.tar.gz` is present inside the backup package.

### Restore Testing Runbook
To verify that object storage backups are fully recoverable without affecting the production MinIO service:
1. Spin up a temporary isolated test MinIO container:
   ```bash
   docker run --name minio_test_restore --network neos-storage -d \
     -e MINIO_ROOT_USER=admin -e MINIO_ROOT_PASSWORD=RestoreTestPassword123! \
     -v /tmp/minio_restore_test_data:/data \
     minio/minio server /data
   ```
2. Stop the container to copy backup files:
   ```bash
   docker stop minio_test_restore
   ```
3. Copy backup files to the temporary volume:
   ```bash
   # Clear target path
   rm -rf /tmp/minio_restore_test_data/*
   
   # Unpack backup
   tar -xzf /srv/neos/shared/backups/neos_backup_*.tar.gz -C /tmp/
   
   # Extract minio data to restore folder
   tar -xzf /tmp/backup_*/minio_data.tar.gz -C /tmp/minio_restore_test_data/
   ```
4. Start the test container:
   ```bash
   docker start minio_test_restore
   ```
5. Verify that buckets and files are present:
   ```bash
   # Set client alias
   mc alias set test http://localhost:9000 admin RestoreTestPassword123!
   
   # List buckets
   mc ls test
   ```
6. Clean up:
   ```bash
   docker rm -f minio_test_restore
   rm -rf /tmp/minio_restore_test_data /tmp/backup_*
   ```

---

## 4. Monitoring & Telemetry

MinIO metrics are scraped by Prometheus directly:
* **Endpoint**: `http://object-store:9000/minio/v2/metrics/cluster` (anonymously scraped inside the private monitoring network).
* **Grafana Dashboard**: Loaded automatically via `neos-minio` provisioning dashboard, tracking:
  - Online nodes.
  - S3 API request volumes and error rates.
  - Object totals.
  - Usable storage capacity.
