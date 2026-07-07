import { NextRequest, NextResponse } from "next/server";
import { MonitoringService } from "@/lib/services/MonitoringService";

export async function GET(request: NextRequest) {
  const role = request.headers.get("x-user-role") || "Read Only";

  try {
    const { alerts, monitors, source } = await MonitoringService.getMonitoringData();
    return NextResponse.json({
      data: { alerts, monitors },
      timestamp: new Date().toISOString(),
      source,
      role,
    });
  } catch (error: any) {
    return NextResponse.json(
      { error: "Internal Server Error", message: error.message },
      { status: 500 }
    );
  }
}
