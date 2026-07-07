import { SystemService } from "./SystemService";
import { DockerService } from "./DockerService";
import { DatabaseService } from "./DatabaseService";
import { RedisService } from "./RedisService";
import { StorageService } from "./StorageService";
import { MonitoringService } from "./MonitoringService";
import { PgBouncerService } from "./PgBouncerService";

export interface ServiceHealth {
  name: string;
  status: "healthy" | "warning" | "critical" | "offline";
  message: string;
}

export interface HealthReport {
  overall: "healthy" | "warning" | "critical" | "offline";
  services: ServiceHealth[];
  timestamp: string;
}

export class HealthService {
  static async getHealthReport(): Promise<HealthReport> {
    const services: ServiceHealth[] = [];

    // 1. PostgreSQL check
    try {
      const { stats } = await DatabaseService.getStats();
      services.push({
        name: "PostgreSQL",
        status: stats.status === "healthy" ? "healthy" : "warning",
        message: `PostgreSQL version ${stats.version} is online.`
      });
    } catch (e: any) {
      services.push({
        name: "PostgreSQL",
        status: "offline",
        message: `PostgreSQL database is unreachable: ${e.message}`
      });
    }

    // 2. PgBouncer check
    try {
      const stats = await PgBouncerService.getStats();
      services.push({
        name: "PgBouncer",
        status: stats.status === "healthy" ? "healthy" : "warning",
        message: "PgBouncer connections pool active."
      });
    } catch (e: any) {
      services.push({
        name: "PgBouncer",
        status: "offline",
        message: `PgBouncer connection pooler is unreachable: ${e.message}`
      });
    }

    // 3. Redis check
    try {
      const { stats } = await RedisService.getStats();
      services.push({
        name: "Redis",
        status: stats.status === "healthy" ? "healthy" : "warning",
        message: `Redis cache is active (Memory: ${(stats.memory.used / 1024 / 1024).toFixed(1)} MB).`
      });
    } catch (e: any) {
      services.push({
        name: "Redis",
        status: "offline",
        message: `Redis cache is unreachable: ${e.message}`
      });
    }

    // 4. MinIO check
    try {
      const { stats } = await StorageService.getStats();
      services.push({
        name: "MinIO",
        status: stats.status === "healthy" ? "healthy" : "warning",
        message: `MinIO storage active with ${stats.totalBuckets} buckets.`
      });
    } catch (e: any) {
      services.push({
        name: "MinIO",
        status: "offline",
        message: `MinIO storage is unreachable: ${e.message}`
      });
    }

    // 5. Docker check
    try {
      const { status } = await DockerService.getDockerStatus();
      services.push({
        name: "Docker",
        status: status.containers.running > 0 ? "healthy" : "warning",
        message: `Docker engine online. Running containers: ${status.containers.running}.`
      });
    } catch (e: any) {
      services.push({
        name: "Docker",
        status: "offline",
        message: `Docker engine is unreachable: ${e.message}`
      });
    }

    // 6. Monitoring check
    try {
      const { alerts } = await MonitoringService.getMonitoringData();
      const hasCritical = alerts.some(a => a.severity === "critical" && a.status === "firing");
      services.push({
        name: "Monitoring",
        status: hasCritical ? "critical" : "healthy",
        message: hasCritical 
          ? `${alerts.filter(a => a.severity === "critical" && a.status === "firing").length} critical firing alarms.` 
          : "All Prometheus scrape targets are healthy."
      });
    } catch (e: any) {
      services.push({
        name: "Monitoring",
        status: "offline",
        message: `Prometheus monitoring is unreachable: ${e.message}`
      });
    }

    // Determine overall health status priority
    let overall: HealthReport["overall"] = "healthy";
    const statusPriority = { healthy: 0, warning: 1, critical: 2, offline: 3 };
    
    for (const service of services) {
      const priority = statusPriority[service.status];
      if (priority > statusPriority[overall]) {
        if (service.status === "offline") {
          overall = "offline";
        } else if (service.status === "critical") {
          overall = "critical";
        } else if (service.status === "warning") {
          overall = "warning";
        }
      }
    }

    // Map offline overall to critical SRE state for notifications
    if (overall === "offline") {
      overall = "critical";
    }

    return {
      overall,
      services,
      timestamp: new Date().toISOString()
    };
  }
}
