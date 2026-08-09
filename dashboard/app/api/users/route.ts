import { NextRequest, NextResponse } from "next/server";
import { DatabaseService } from "@/lib/services/DatabaseService";
import { mockUsers } from "@/lib/mock-data";

export async function GET(request: NextRequest) {
  const role = request.headers.get("x-user-role") || "Read Only";

  try {
    const { users, source } = await DatabaseService.getPlatformUsers();
    return NextResponse.json({
      data: users,
      timestamp: new Date().toISOString(),
      source,
      role,
    });
  } catch (err: any) {
    return NextResponse.json({
      data: mockUsers,
      timestamp: new Date().toISOString(),
      source: "mock",
      role,
    });
  }
}
