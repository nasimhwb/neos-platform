import { SystemService } from "./SystemService";
import { DockerService } from "./DockerService";
import { DatabaseService } from "./DatabaseService";
import { RedisService } from "./RedisService";
import { StorageService } from "./StorageService";
import { BackupService } from "./BackupService";
import { PgBouncerService } from "./PgBouncerService";
import { HealthService } from "./HealthService";
import { NotificationService } from "./NotificationService";
import fs from "fs";
import path from "path";

export interface Snapshot {
  system: any;
  docker: any;
  database: any;
  redis: any;
  storage: any;
  backups: any;
  pgbouncer: any;
  health: any;
  timestamp: string;
}

let intervalId: NodeJS.Timeout | null = null;
let currentSnapshot: Snapshot | null = null;

export class SchedulerService {
  private static getSnapshotPath(): string {
    const dir = path.join(process.cwd(), "logs");
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }
    return path.join(dir, "snapshots.json");
  }

  static start() {
    if (intervalId) return;

    console.log("[Scheduler] Starting background metrics snapshot loop (15s)...");
    
    // Trigger immediate collection on thread boot
    this.collectSnapshot().catch(console.error);

    intervalId = setInterval(async () => {
      try {
        await this.collectSnapshot();
      } catch (err) {
        console.error("[Scheduler] Error during metrics collection:", err);
      }
    }, 15000); // 15s collection interval
  }

  static async getLatestSnapshot(): Promise<Snapshot> {
    // Auto-boot scheduler on query if inactive
    if (!intervalId) {
      this.start();
    }

    if (currentSnapshot) return currentSnapshot;

    // Load from disk if available
    const filePath = this.getSnapshotPath();
    if (fs.existsSync(filePath)) {
      try {
        const raw = fs.readFileSync(filePath, "utf-8");
        currentSnapshot = JSON.parse(raw);
        return currentSnapshot!;
      } catch {}
    }

    // fallback to immediate query
    await this.collectSnapshot();
    return currentSnapshot!;
  }

  private static async collectSnapshot(): Promise<void> {
    console.log("[Scheduler] Gathering snapshots from all platform services...");

    const [systemRes, dockerRes, databaseRes, redisRes, storageRes, backupsRes, pgbouncerRes, healthRes] = await Promise.allSettled([
      SystemService.getMetrics().then(r => r.metrics),
      Promise.all([
        DockerService.getDockerStatus().then(r => r.status),
        DockerService.getContainers().then(r => r.containers),
        DockerService.getNetworks().then(r => r.networks),
        DockerService.getVolumes().then(r => r.volumes)
      ]).then(([status, containers, networks, volumes]) => ({ status, containers, networks, volumes })),
      DatabaseService.getStats().then(r => r.stats),
      RedisService.getStats().then(r => r.stats),
      StorageService.getStats().then(r => r.stats),
      BackupService.getBackups().then(r => r.backups),
      PgBouncerService.getStats(),
      HealthService.getHealthReport()
    ]);

    const system = systemRes.status === "fulfilled" ? systemRes.value : null;
    const docker = dockerRes.status === "fulfilled" ? dockerRes.value : null;
    const database = databaseRes.status === "fulfilled" ? databaseRes.value : null;
    const redis = redisRes.status === "fulfilled" ? redisRes.value : null;
    const storage = storageRes.status === "fulfilled" ? storageRes.value : null;
    const backups = backupsRes.status === "fulfilled" ? backupsRes.value : null;
    const pgbouncer = pgbouncerRes.status === "fulfilled" ? pgbouncerRes.value : null;
    const health = healthRes.status === "fulfilled" ? healthRes.value : null;

    currentSnapshot = {
      system,
      docker,
      database,
      redis,
      storage,
      backups,
      pgbouncer,
      health,
      timestamp: new Date().toISOString()
    };

    // Commit snapshot to file system for dashboard access persistence
    try {
      fs.writeFileSync(this.getSnapshotPath(), JSON.stringify(currentSnapshot, null, 2), "utf-8");
    } catch {}

    if (system && system.disk && system.disk.usagePercent > 90) {
      await NotificationService.sendNotification(
        "DiskUsageCritical",
        `Root disk usage is at ${system.disk.usagePercent}% on host root partition.`
      );
    }

    if (docker && docker.containers) {
      for (const container of docker.containers) {
        if (container.state === "exited" || container.state === "stopped") {
          await NotificationService.sendNotification(
            "ContainerOffline",
            `Container '${container.name}' is offline (State: ${container.state}).`
          );
        }
      }
    }

    if (health && health.overall === "critical") {
      const degraded = health.services.filter((s: any) => s.status === "offline" || s.status === "critical");
      const details = degraded.map((s: any) => `${s.name}: ${s.status} (${s.message})`).join(", ");
      await NotificationService.sendNotification(
        "PlatformHealthDegraded",
        `Infrastructure health entered degraded state: ${details}`
      );
    }
  }
}
