import { NextRequest, NextResponse } from "next/server";
import { SchedulerService } from "@/lib/services/SchedulerService";

export async function GET(request: NextRequest) {
  const role = request.headers.get("x-user-role") || "Read Only";

  try {
    const snapshot = await SchedulerService.getLatestSnapshot();
    const backups = snapshot.backups;

    return NextResponse.json({
      data: backups,
      timestamp: snapshot.timestamp,
      source: "cached",
      role,
    });
  } catch (error: any) {
    return NextResponse.json(
      { error: "Internal Server Error", message: error.message },
      { status: 500 }
    );
  }
}
