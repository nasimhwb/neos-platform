import { NextRequest, NextResponse } from "next/server";
import { DeploymentService } from "@/lib/services/DeploymentService";
import { AuditService } from "@/lib/services/AuditService";

export async function GET(request: NextRequest) {
  const role = request.headers.get("x-user-role") || "Read Only";

  try {
    const { platform, history, source } = await DeploymentService.getDeploymentData();
    return NextResponse.json({
      data: { platform, history },
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

export async function POST(request: NextRequest) {
  const role = request.headers.get("x-user-role") || "Read Only";
  const clientIp = (request as any).ip || request.headers.get("x-forwarded-for") || "127.0.0.1";

  try {
    const body = await request.json();
    const { action } = body;

    if (action !== "rollback") {
      return NextResponse.json(
        { error: "Bad Request", message: "Invalid action. Supported actions: rollback" },
        { status: 400 }
      );
    }

    // Log the rollback command in the Audit log
    await AuditService.logAction(
      "Restore", // Restore maps to Rollback in Audit Log categories
      role,
      "Triggered platform deployment rollback",
      clientIp,
      "success"
    );

    return NextResponse.json({
      success: true,
      message: "Rollback process initiated successfully.",
      timestamp: new Date().toISOString(),
    });
  } catch (error: any) {
    return NextResponse.json(
      { error: "Internal Server Error", message: error.message },
      { status: 500 }
    );
  }
}
