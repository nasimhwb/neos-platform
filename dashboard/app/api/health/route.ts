import { NextResponse } from "next/server";
import { SystemService } from "@/lib/services/SystemService";
import { DockerService } from "@/lib/services/DockerService";
import { DatabaseService } from "@/lib/services/DatabaseService";
import { RedisService } from "@/lib/services/RedisService";
import { StorageService } from "@/lib/services/StorageService";
import { MonitoringService } from "@/lib/services/MonitoringService";

export async function GET() {
  const services = [
    { name: "PostgreSQL", status: "unknown" },
    { name: "Redis", status: "unknown" },
    { name: "MinIO", status: "unknown" },
    { name: "Docker", status: "unknown" },
    { name: "Monitoring", status: "unknown" },
  ];

  let systemMetrics;
  let overall = "healthy";

  // Query each service health status
  try {
    const sysData = await SystemService.getMetrics();
    systemMetrics = sysData.metrics;
  } catch (e) {
    overall = "degraded";
  }

  try {
    const { stats } = await DatabaseService.getStats();
    services[0].status = stats.status;
  } catch {
    services[0].status = "unhealthy";
    overall = "degraded";
  }

  try {
    const { stats } = await RedisService.getStats();
    services[1].status = stats.status;
  } catch {
    services[1].status = "unhealthy";
    overall = "degraded";
  }

  try {
    const { stats } = await StorageService.getStats();
    services[2].status = stats.status;
  } catch {
    services[2].status = "unhealthy";
    overall = "degraded";
  }

  try {
    const { status } = await DockerService.getDockerStatus();
    services[3].status = status.containers.running > 0 ? "healthy" : "degraded";
  } catch {
    services[3].status = "unhealthy";
    overall = "degraded";
  }

  try {
    const { alerts } = await MonitoringService.getMonitoringData();
    const hasCritical = alerts.some(a => a.severity === "critical" && a.status === "firing");
    services[4].status = hasCritical ? "degraded" : "healthy";
  } catch {
    services[4].status = "unhealthy";
  }

  // Evaluate overall health
  const anyUnhealthy = services.some(s => s.status === "unhealthy");
  if (anyUnhealthy) {
    overall = "unhealthy";
  }

  return NextResponse.json({
    data: {
      overall,
      services,
      system: {
        cpuUsage: systemMetrics?.cpu.usage || 0,
        memoryUsage: systemMetrics?.memory.usagePercent || 0,
        diskUsage: systemMetrics?.disk.usagePercent || 0,
      },
    },
    timestamp: new Date().toISOString(),
    source: "live",
  });
}
