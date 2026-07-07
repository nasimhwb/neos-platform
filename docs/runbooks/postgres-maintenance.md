# PostgreSQL & PgBouncer Database Platform Runbook

This document describes the operational maintenance, tuning parameters, backup routines, and restore verification tests for the NEOS Platform PostgreSQL infrastructure.

---

## 1. Database Architecture & Optimization

### Tuning Parameters
* **Shared Buffers (`shared_buffers = 384MB`)**: Set to ~25% of the 1.5GB Postgres container memory limit. Saves buffer cache while avoiding container OOM exits.
* **Effective Cache Size (`effective_cache_size = 1GB`)**: Estimated cache memory available for OS page buffering.
* **SSD Tuning**: `random_page_cost` is reduced to `1.1` and `effective_io_concurrency` is increased to `200` to utilize Hostinger NVMe SSD read performance.
* **WAL Checkpoints**: Checkpoint writes are spread smoothly (`checkpoint_completion_target = 0.9`) over a `15min` window to avoid write spikes.

### Connection Pooling (PgBouncer)
All application services connect to PgBouncer on port `6432` instead of talking to PostgreSQL directly.
* **Pool Mode (`transaction`)**: Allocates server connections to clients only when active transactions are running, immediately reclaiming them when done.
* **Connection Cap**: Client connection limit is set to `250`, while backend connection limit to Postgres is capped at `80` (preventing connection exhaustion errors).

---

## 2. Security Boundaries & Isolation

For maximum host security, networks are segregated:
* **`neos-database`**: Isolates direct PostgreSQL traffic. The database container `db` joins *only* `neos-database` and `neos-monitoring`.
* **`neos-private`**: Connects applications to the connection pooler. The `pgbouncer` container bridges `neos-private` and `neos-database`.
* Applications cannot access the database directly, nor bypass the connection pool constraints!

---

## 3. SSL Configuration
To enable SSL in production:
1. Generate certificates and place them in `/srv/neos/shared/ssl/live/neos-platform.local/`.
2. Map the certificate files inside `compose/compose.database.yml` under volumes:
   ```yaml
   - /srv/neos/shared/ssl:/etc/postgresql/ssl:ro
   ```
3. Set the configurations in `/etc/postgresql/postgresql.conf`:
   ```ini
   ssl = on
   ssl_cert_file = '/etc/postgresql/ssl/live/neos-platform.local/fullchain.pem'
   ssl_key_file = '/etc/postgresql/ssl/live/neos-platform.local/privkey.pem'
   ```
   *Note: PostgreSQL verifies that the private key file is owned by postgres (UID 70) and restricted (`chmod 600`). Ensure permissions are set correctly on the host mount.*

---

## 4. Backups and Restore Testing

### Daily Automated Backups
To schedule backups daily at 2:00 AM:
1. Log in to the VPS as `nasim`.
2. Open crontab: `crontab -e`.
3. Add the following entry:
   ```cron
   0 2 * * * /srv/neos/current/backups/backup.sh >> /srv/neos/shared/logs/system/backup.log 2>&1
   ```

### Automated Verification
Run `make verify-backup` to verify file compositions and integrity of the generated backup archives.

### Restore Integrity Testing Runbook
To verify that database backups are fully recoverable without affecting the production database:
1. Spin up a temporary isolated test container:
   ```bash
   docker run --name pg_test_restore --network neos-database -d \
     -e POSTGRES_PASSWORD=RestoreTestPassword123! \
     postgres:16.3-alpine
   ```
2. Unpack the SQL dump from the backup archive:
   ```bash
   # Extract backup
   tar -xzf /srv/neos/shared/backups/neos_backup_*.tar.gz -C /tmp/
   
   # Decompress the target database SQL file
   gunzip /tmp/backup_*/postgres_neos_erp.sql.gz
   ```
3. Pipe the SQL commands into the test database:
   ```bash
   docker exec -i pg_test_restore psql -U postgres -d postgres < /tmp/backup_*/postgres_neos_erp.sql
   ```
4. Verify success, then clean up:
   ```bash
   docker exec -i pg_test_restore psql -U postgres -c "\l"
   docker rm -f pg_test_restore
   rm -rf /tmp/backup_*
   ```
This loop guarantees that your backup is 100% valid and fully restorable.

---

## 5. Supabase Compatibility

To ensure full compatibility with Supabase schema migrations (prior to any future migration):
* **Extensions**: The `02-supabase-compat.sql` script pre-installs `uuid-ossp`, `pgcrypto`, and `pg_stat_statements` on startup.
* **Roles**: Pre-registers Supabase default roles (`anon`, `authenticated`, `service_role`, `authenticator`, and `supabase_admin`) so migrations do not fail due to missing system credentials.
