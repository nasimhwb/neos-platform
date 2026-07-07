import { NextRequest, NextResponse } from "next/server";
import { SystemService } from "@/lib/services/SystemService";
import { DeploymentService } from "@/lib/services/DeploymentService";

export async function GET(request: NextRequest) {
  const role = request.headers.get("x-user-role") || "Read Only";
  
  try {
    const { metrics, source: sysSource } = await SystemService.getMetrics();
    const { platform } = await DeploymentService.getDeploymentData();
    
    return NextResponse.json({
      data: { metrics, platform },
      timestamp: new Date().toISOString(),
      source: sysSource,
      role,
    });
  } catch (error: any) {
    return NextResponse.json(
      { error: "Internal Server Error", message: error.message },
      { status: 500 }
    );
  }
}
