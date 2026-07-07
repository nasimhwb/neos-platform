import { HealthService } from "../lib/services/HealthService";
import { DatabaseService } from "../lib/services/DatabaseService";
import { RedisService } from "../lib/services/RedisService";
import { StorageService } from "../lib/services/StorageService";
import { DockerService } from "../lib/services/DockerService";
import { MonitoringService } from "../lib/services/MonitoringService";
import { PgBouncerService } from "../lib/services/PgBouncerService";

// Chaos testing harness to simulate dependency failures
async function runSimulation() {
  console.log("=========================================================");
  console.log("=== NEOS HEALTH ENGINE FAILURE MODE SIMULATION ===");
  console.log("=========================================================");

  let testPassed = true;

  const assertOverall = (report: any, expectedOverall: string, testName: string) => {
    if (report.overall === expectedOverall) {
      console.log(`[PASS] ${testName}: Aggregate status is '${report.overall}'`);
    } else {
      console.error(`[FAIL] ${testName}: Expected '${expectedOverall}' but got '${report.overall}'`);
      testPassed = false;
    }
  };

  // Scenario 1: All dependencies fully healthy
  console.log("\n--- Scenario 1: Nominal State (All Healthy) ---");
  DatabaseService.getStats = async () => ({ stats: { status: "healthy", version: "Postgres 16", databases: [], users: [] } as any, source: "live" });
  PgBouncerService.getStats = async () => ({ status: "healthy", pools: [], stats: [], clients: [] });
  RedisService.getStats = async () => ({ stats: { status: "healthy", memory: { used: 1024 } } as any, source: "live" });
  StorageService.getStats = async () => ({ stats: { status: "healthy", totalBuckets: 4 } as any, source: "live" });
  DockerService.getDockerStatus = async () => ({ status: { containers: { running: 5 } } as any, source: "live" });
  MonitoringService.getMonitoringData = async () => ({ alerts: [], monitors: [], source: "live" });

  let report = await HealthService.getHealthReport();
  assertOverall(report, "healthy", "Nominal Health aggregation");

  // Scenario 2: Database down (Offline)
  console.log("\n--- Scenario 2: Major Service Outage (Database Offline) ---");
  DatabaseService.getStats = async () => { throw new Error("Connection timed out"); };
  
  report = await HealthService.getHealthReport();
  assertOverall(report, "critical", "Database Outage aggregation (offline maps to critical overall)");

  // Scenario 3: Firing Critical Alert (Critical)
  console.log("\n--- Scenario 3: Firing Alerts (Critical) ---");
  DatabaseService.getStats = async () => ({ stats: { status: "healthy", version: "Postgres 16", databases: [], users: [] } as any, source: "live" });
  MonitoringService.getMonitoringData = async () => ({
    alerts: [
      { id: "123", name: "HighCpuUsage", severity: "critical", status: "firing", message: "CPU > 95%", startsAt: "", labels: {} }
    ],
    monitors: [],
    source: "live"
  });

  report = await HealthService.getHealthReport();
  assertOverall(report, "critical", "Firing alerts aggregation");

  // Scenario 4: Degraded status (Warning)
  console.log("\n--- Scenario 4: Non-Fatal Issues (Warnings) ---");
  MonitoringService.getMonitoringData = async () => ({ alerts: [], monitors: [], source: "live" });
  DatabaseService.getStats = async () => ({ stats: { status: "warning", version: "Postgres 16", databases: [], users: [] } as any, source: "live" });

  report = await HealthService.getHealthReport();
  assertOverall(report, "warning", "Warning / degradation aggregation");

  console.log("\n=========================================================");
  if (testPassed) {
    console.log("=== [SUCCESS] ALL FAILURE MODE SIMULATIONS PASSED! ===");
    console.log("=========================================================");
    process.exit(0);
  } else {
    console.error("=== [FAILURE] HEALTH STATE AGGREGATION WAS INCORRECT! ===");
    console.log("=========================================================");
    process.exit(1);
  }
}

runSimulation().catch(e => {
  console.error("Simulation run crash:", e);
  process.exit(1);
});
