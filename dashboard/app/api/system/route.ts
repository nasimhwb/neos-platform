import { NextResponse } from "next/server";
import { mockSystemMetrics, mockPlatformInfo } from "@/lib/mock-data";

export async function GET() {
  return NextResponse.json({
    data: { metrics: mockSystemMetrics, platform: mockPlatformInfo },
    timestamp: new Date().toISOString(),
    source: "mock",
  });
}
