import { NextResponse } from "next/server";
import { mockMinioStats } from "@/lib/mock-data";

export async function GET() {
  return NextResponse.json({ data: mockMinioStats, timestamp: new Date().toISOString(), source: "mock" });
}
