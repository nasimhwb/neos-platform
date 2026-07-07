import { NextRequest, NextResponse } from "next/server";
import { StorageService } from "@/lib/services/StorageService";

export async function GET(request: NextRequest) {
  const role = request.headers.get("x-user-role") || "Read Only";

  try {
    const { stats, source } = await StorageService.getStats();
    return NextResponse.json({
      data: stats,
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
