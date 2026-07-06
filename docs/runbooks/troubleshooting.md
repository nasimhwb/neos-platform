# Platform Troubleshooting Guide

This guide describes diagnostics and solutions for common operational issues on the Neos Platform VPS node.

---

## 1. System Diagnosis Commands

Always run `make doctor` first to execute the self-diagnostic suite. It highlights CPU, RAM, Disk, container health, SSL expirations, and port resolutions.

---

## 2. Common Scenarios

### Scenario A: Out-Of-Memory (OOM) Crashes
* **Symptom**: PostgreSQL or Redis container exits suddenly with exit code 137. `make doctor` reports low RAM.
* **Diagnosis**: Check kernel logs for OOM-killer activity:
  ```bash
  dmesg -T | grep -i oom
  journalctl -k | grep -i oom
  ```
* **Solution**:
  1. Verify container resource limits in `compose/compose.database.yml`.
  2. If Postgres or Redis is exceeding limits, tune down cache limits:
     - PostgreSQL: reduce `shared_buffers` or `work_mem` in `configs/postgres/postgresql.conf`.
     - Redis: ensure `maxmemory` is enforced in `configs/redis/redis.conf`.
  3. Clean host memory by pruning unused Docker caches: `make clean`.

### Scenario B: Storage Exhaustion (Disk Space)
* **Symptom**: MinIO writes fail or containers report `No space left on device`.
* **Diagnosis**: Check disk space usage:
  ```bash
  df -h
  docker system df
  ```
* **Solution**:
  1. Trigger clean-up of dangling images, stopped containers, and build cache:
     ```bash
     make clean
     ```
  2. Check local backup archives in `/srv/neos/shared/backups/`. Ensure the retention daemon is running and pruning backups older than 14 days.

### Scenario C: PostgreSQL Database Lock Contention
* **Symptom**: Application requests hang or database queries time out.
* **Diagnosis**: Connect to PostgreSQL and query active locks:
  ```bash
  docker exec -it neos_postgres psql -U postgres -d postgres -c "
  SELECT blocked_locks.pid     AS blocked_pid,
         blocked_activity.usename  AS blocked_user,
         blocking_locks.pid    AS blocking_pid,
         blocking_activity.usename AS blocking_user,
         blocked_activity.query    AS blocked_statement,
         blocking_activity.query   AS blocking_statement
  FROM  pg_catalog.pg_locks         blocked_locks
  JOIN pg_catalog.pg_stat_activity blocked_activity ON blocked_activity.pid = blocked_locks.pid
  JOIN pg_catalog.pg_locks         blocking_locks 
      ON blocking_locks.locktype = blocked_locks.locktype
      AND blocking_locks.database IS NOT DISTINCT FROM blocked_locks.database
      AND blocking_locks.relation IS NOT DISTINCT FROM blocked_locks.relation
      AND blocking_locks.page IS NOT DISTINCT FROM blocked_locks.page
      AND blocking_locks.tuple IS NOT DISTINCT FROM blocked_locks.tuple
      AND blocking_locks.virtualxid IS NOT DISTINCT FROM blocked_locks.virtualxid
      AND blocking_locks.transactionid IS NOT DISTINCT FROM blocked_locks.transactionid
      AND blocking_locks.classid IS NOT DISTINCT FROM blocked_locks.classid
      AND blocking_locks.objid IS NOT DISTINCT FROM blocked_locks.objid
      AND blocking_locks.objsubid IS NOT DISTINCT FROM blocked_locks.objsubid
      AND blocking_locks.pid != blocked_locks.pid
  JOIN pg_catalog.pg_stat_activity blocking_activity ON blocking_activity.pid = blocking_locks.pid
  WHERE NOT blocked_locks.granted;"
  ```
* **Solution**:
  Terminate the blocking pid:
  ```bash
  docker exec -it neos_postgres psql -U postgres -c "SELECT pg_cancel_backend(BLOCKING_PID);"
  # Or force terminate:
  docker exec -it neos_postgres psql -U postgres -c "SELECT pg_terminate_backend(BLOCKING_PID);"
  ```

### Scenario D: Let's Encrypt Certificate Renewal Failures
* **Symptom**: Browsers warn about insecure connection/invalid SSL cert.
* **Diagnosis**: Check Certbot renewal log:
  ```bash
  sudo certbot renew --dry-run
  ```
* **Solution**:
  1. Verify port 80 is listening on the host.
  2. Verify Nginx reverse proxy is running. Nginx must handle the ACME challenge request at `/.well-known/acme-challenge/` and serve it from `/srv/neos/shared/www/`.
  3. Check directory permissions: `/srv/neos/shared/www/` must be readable by Nginx.
