import { NextResponse } from "next/server";
import { mockSystemMetrics, mockDockerStatus, mockPostgresStats, mockRedisStats, mockMinioStats } from "@/lib/mock-data";

export async function GET() {
  const services = [
    { name: "PostgreSQL", status: mockPostgresStats.status },
    { name: "Redis", status: mockRedisStats.status },
    { name: "MinIO", status: mockMinioStats.status },
    { name: "Docker", status: mockDockerStatus.containers.running > 0 ? "healthy" : "unhealthy" },
  ];

  const allHealthy = services.every(s => s.status === "healthy");
  const anyUnhealthy = services.some(s => s.status === "unhealthy");

  return NextResponse.json({
    data: {
      overall: anyUnhealthy ? "unhealthy" : allHealthy ? "healthy" : "degraded",
      services,
      system: {
        cpuUsage: mockSystemMetrics.cpu.usage,
        memoryUsage: mockSystemMetrics.memory.usagePercent,
        diskUsage: mockSystemMetrics.disk.usagePercent,
      },
    },
    timestamp: new Date().toISOString(),
    source: "mock",
  });
}
