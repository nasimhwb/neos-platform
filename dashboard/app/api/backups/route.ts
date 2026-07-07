import { NextRequest, NextResponse } from "next/server";
import { BackupService } from "@/lib/services/BackupService";

export async function GET(request: NextRequest) {
  const role = request.headers.get("x-user-role") || "Read Only";

  try {
    const { backups, source } = await BackupService.getBackups();
    return NextResponse.json({
      data: backups,
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
