import { NextResponse } from "next/server";
import { mockAlerts, mockUptimeMonitors } from "@/lib/mock-data";

export async function GET() {
  return NextResponse.json({
    data: { alerts: mockAlerts, monitors: mockUptimeMonitors },
    timestamp: new Date().toISOString(),
    source: "mock",
  });
}
