# Redis Cache Production Operations & Maintenance Runbook

This document describes the operational maintenance, persistence configurations, backup routines, and recovery verification procedures for the NEOS Platform Redis 8 database engine.

---

## 1. Production Configuration & Policies

Redis is configured at `configs/redis/redis.conf` with optimized persistence and eviction parameters:

### Dual Persistence
For absolute data durability and high-throughput crash recovery, we run a hybrid model:
* **RDB (Snapshotting)**: Writes binary state snapshots to `dump.rdb` at set intervals:
  - `save 900 1` (15 min if 1 key changed)
  - `save 300 10` (5 min if 10 keys changed)
  - `save 60 10000` (1 min if 10000 keys changed)
* **AOF (Append Only File)**: Logs every write operation to `appendonly.aof` inside `/data/appendonlydir/` once per second (`appendfsync everysec`).
* **AOF Preambles**: `aof-use-rdb-preamble yes` is enabled, compressing append-only logs with standard RDB formatting to ensure faster startup parsing.

### Memory & Eviction
* **`maxmemory 512mb`**: Restricts the cache container limit to 512MB RAM.
* **`maxmemory-policy allkeys-lru`**: When memory is full, eviction terminates the Least Recently Used (LRU) keys across the entire database to prevent OOM errors.
* **Lazy Freeing**: Enabled (`lazyfree-lazy-eviction yes`) to clear large keys asynchronously in background threads, avoiding blocking client requests.

---

## 2. Operations & Maintenance Tasks

### Task A: Checking Memory Fragmentation
If Redis memory usage is high but active keys are low, check the fragmentation ratio:
1. Access Redis CLI inside the container:
   ```bash
   docker exec -it neos_redis redis-cli -a "$REDIS_PASSWORD"
   ```
2. Query memory stats:
   ```
   127.0.0.1:6379> info memory
   ```
3. Locate `mem_fragmentation_ratio`.
   * **Ratio > 1.5**: Indicates high memory fragmentation. Trigger active defragmentation:
     ```
     127.0.0.1:6379> config set activedefrag yes
     ```

### Task B: Auditing Backups Composition
To verify that database backups contains both RDB and AOF archives:
1. Extract the backup package:
   ```bash
   tar -xzf /srv/neos/shared/backups/neos_backup_*.tar.gz -C /tmp/
   ```
2. Check the extraction directory:
   - `redis_dump.rdb` must exist.
   - `redis_appendonlydir/` must exist and contain AOF log files.

---

## 3. Restore and Recovery Verification Loop

To test the restore logic of RDB and AOF files safely without touching the production container:
1. Spin up a temporary isolated test Redis container:
   ```bash
   docker run --name redis_test_restore --network neos-database -d \
     -v /tmp/redis_restore_test_data:/data \
     redis:8.0-M02-alpine
   ```
2. Stop the test container to safely copy files:
   ```bash
   docker stop redis_test_restore
   ```
3. Copy the backup RDB and AOF folder to the temporary volume path:
   ```bash
   # Clear target data directory
   rm -rf /tmp/redis_restore_test_data/*
   
   # Copy backup files
   cp /tmp/backup_*/redis_dump.rdb /tmp/redis_restore_test_data/dump.rdb
   cp -R /tmp/backup_*/redis_appendonlydir /tmp/redis_restore_test_data/appendonlydir
   ```
4. Start the test container:
   ```bash
   docker start redis_test_restore
   ```
5. Connect to the test container and verify keys are present:
   ```bash
   docker exec -it redis_test_restore redis-cli ping
   # Query keys count
   docker exec -it redis_test_restore redis-cli dbsize
   ```
6. Clean up:
   ```bash
   docker rm -f redis_test_restore
   rm -rf /tmp/redis_restore_test_data /tmp/backup_*
   ```
This loop ensures your dual-persistence backups remain 100% testable and recoverable!
