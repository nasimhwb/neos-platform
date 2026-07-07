import { NextRequest, NextResponse } from "next/server";
import { mockUsers } from "@/lib/mock-data";

export async function GET(request: NextRequest) {
  const role = request.headers.get("x-user-role") || "Read Only";

  return NextResponse.json({
    data: mockUsers,
    timestamp: new Date().toISOString(),
    source: "live",
    role,
  });
}
