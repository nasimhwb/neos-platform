import { NextRequest, NextResponse } from "next/server";
import { SchedulerService } from "@/lib/services/SchedulerService";
import { DockerService } from "@/lib/services/DockerService";
import { AuditService } from "@/lib/services/AuditService";

export async function GET(request: NextRequest) {
  const role = request.headers.get("x-user-role") || "Read Only";

  try {
    const snapshot = await SchedulerService.getLatestSnapshot();
    const { status, containers, networks, volumes } = snapshot.docker || { status: null, containers: [], networks: [], volumes: [] };

    return NextResponse.json({
      data: { status, containers, networks, volumes },
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

export async function POST(request: NextRequest) {
  const role = request.headers.get("x-user-role") || "Read Only";
  const clientIp = (request as any).ip || request.headers.get("x-forwarded-for") || "127.0.0.1";

  try {
    const body = await request.json();
    const { id, action } = body;

    if (!id || action !== "restart") {
      return NextResponse.json(
        { error: "Bad Request", message: "Missing id or invalid action. Supported actions: restart" },
        { status: 400 }
      );
    }

    // Attempt container restart
    const success = await DockerService.restartContainer(id);

    if (success) {
      // Log action to Audit System
      await AuditService.logAction(
        "Restart",
        role,
        `Restarted container with ID: ${id}`,
        clientIp,
        "success"
      );

      return NextResponse.json({
        success: true,
        message: `Container ${id} restart request dispatched successfully.`,
        timestamp: new Date().toISOString(),
      });
    } else {
      await AuditService.logAction(
        "Restart",
        role,
        `Failed to restart container with ID: ${id}`,
        clientIp,
        "failed"
      );

      return NextResponse.json(
        { error: "Internal Server Error", message: `Failed to restart container ${id}.` },
        { status: 500 }
      );
    }
  } catch (error: any) {
    return NextResponse.json(
      { error: "Internal Server Error", message: error.message },
      { status: 500 }
    );
  }
}
