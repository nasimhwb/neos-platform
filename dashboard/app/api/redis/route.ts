import { NextResponse } from "next/server";
import { mockRedisStats } from "@/lib/mock-data";

export async function GET() {
  return NextResponse.json({ data: mockRedisStats, timestamp: new Date().toISOString(), source: "mock" });
}
