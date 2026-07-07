import { NextResponse } from "next/server";
import { SchedulerService } from "@/lib/services/SchedulerService";

export async function GET() {
  try {
    const snapshot = await SchedulerService.getLatestSnapshot();
    const healthReport = snapshot.health || { overall: "healthy", services: [] };
    const systemMetrics = snapshot.system;

    return NextResponse.json({
      data: {
        overall: healthReport.overall,
        services: healthReport.services,
        system: {
          cpuUsage: systemMetrics?.cpu.usage || 0,
          memoryUsage: systemMetrics?.memory.usagePercent || 0,
          diskUsage: systemMetrics?.disk.usagePercent || 0,
        },
      },
      timestamp: snapshot.timestamp,
      source: "cached",
    });
  } catch (error: any) {
    return NextResponse.json(
      { error: "Internal Server Error", message: error.message },
      { status: 500 }
    );
  }
}
