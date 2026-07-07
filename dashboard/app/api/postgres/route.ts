import { NextResponse } from "next/server";
import { mockPostgresStats } from "@/lib/mock-data";

export async function GET() {
  return NextResponse.json({ data: mockPostgresStats, timestamp: new Date().toISOString(), source: "mock" });
}
