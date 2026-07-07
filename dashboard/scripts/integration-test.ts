import { SystemService } from "../lib/services/SystemService";
import { DockerService } from "../lib/services/DockerService";
import { DatabaseService } from "../lib/services/DatabaseService";
import { RedisService } from "../lib/services/RedisService";
import { StorageService } from "../lib/services/StorageService";
import { BackupService } from "../lib/services/BackupService";
import { PgBouncerService } from "../lib/services/PgBouncerService";
import { HealthService } from "../lib/services/HealthService";

async function runTests() {
  console.log("=========================================================");
  console.log("=== RUNNING INTEGRATION TESTS FOR NEOS PLATFORM SRE ===");
  console.log("=========================================================");

  let passed = true;

  const assert = (condition: boolean, msg: string) => {
    if (condition) {
      console.log(`[PASS] ${msg}`);
    } else {
      console.error(`[FAIL] ${msg}`);
      passed = false;
    }
  };

  // 1. System Service
  try {
    const { metrics } = await SystemService.getMetrics();
    assert(metrics.cpu !== undefined, "SystemService: retrieves CPU load average.");
    assert(metrics.memory !== undefined, "SystemService: retrieves Memory telemetry.");
    assert(metrics.disk !== undefined, "SystemService: retrieves Disk partitions.");
  } catch (e: any) {
    assert(false, `SystemService Integration Error: ${e.message}`);
  }

  // 2. Docker Service
  try {
    const { status } = await DockerService.getDockerStatus();
    assert(status.version !== undefined, "DockerService: gathers Docker daemon engine version.");
    assert(status.containers !== undefined, "DockerService: retrieves containers telemetry status.");
  } catch (e: any) {
    assert(false, `DockerService Integration Error: ${e.message}`);
  }

  // 3. PostgreSQL Database Service
  try {
    const { stats } = await DatabaseService.getStats();
    assert(stats.version !== undefined, "DatabaseService: gathers PostgreSQL server version.");
    assert(stats.databases !== undefined, "DatabaseService: lists active databases.");
    assert(stats.users !== undefined, "DatabaseService: lists active database roles.");
  } catch (e: any) {
    assert(false, `DatabaseService Integration Error: ${e.message}`);
  }

  // 4. PgBouncer connection pooler
  try {
    const stats = await PgBouncerService.getStats();
    assert(stats.pools !== undefined, "PgBouncerService: gathers active connection pools.");
    assert(stats.stats !== undefined, "PgBouncerService: gathers active transaction statistics.");
    assert(stats.clients !== undefined, "PgBouncerService: gathers client descriptors list.");
  } catch (e: any) {
    assert(false, `PgBouncerService Integration Error: ${e.message}`);
  }

  // 5. Redis Service
  try {
    const { stats } = await RedisService.getStats();
    assert(stats.memory !== undefined, "RedisService: parses active caching memory consumption.");
    assert(stats.clients !== undefined, "RedisService: parses clients telemetry.");
  } catch (e: any) {
    assert(false, `RedisService Integration Error: ${e.message}`);
  }

  // 6. Storage Service
  try {
    const { stats } = await StorageService.getStats();
    assert(stats.buckets !== undefined, "StorageService: lists MinIO buckets.");
    assert(stats.totalBuckets !== undefined, "StorageService: parses buckets count.");
  } catch (e: any) {
    assert(false, `StorageService Integration Error: ${e.message}`);
  }

  // 7. Backup Service
  try {
    const { backups } = await BackupService.getBackups();
    assert(backups !== undefined, "BackupService: scans file system backups directory.");
  } catch (e: any) {
    assert(false, `BackupService Integration Error: ${e.message}`);
  }

  // 8. Health Engine Service
  try {
    const report = await HealthService.getHealthReport();
    assert(report.overall !== undefined, "HealthService: returns unified health engine overall status.");
    assert(report.services.length > 0, "HealthService: parses status messages for each core service dependency.");
  } catch (e: any) {
    assert(false, `HealthService Integration Error: ${e.message}`);
  }

  console.log("=========================================================");
  if (passed) {
    console.log("=== [SUCCESS] ALL SRE INTEGRATION TESTS COMPLETED! ===");
    console.log("=========================================================");
    process.exit(0);
  } else {
    console.error("=== [FAILURE] SOME SRE INTEGRATION TESTS DEGRADED! ===");
    console.log("=========================================================");
    process.exit(1);
  }
}

runTests().catch(e => {
  console.error("Test runner process exception:", e);
  process.exit(1);
});
