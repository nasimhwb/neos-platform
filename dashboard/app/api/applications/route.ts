import { NextRequest, NextResponse } from "next/server";
import { DockerService } from "@/lib/services/DockerService";
import { mockApplications } from "@/lib/mock-data";
import { Application } from "@/lib/types";

export async function GET(request: NextRequest) {
  const role = request.headers.get("x-user-role") || "Read Only";

  try {
    const { containers } = await DockerService.getContainers();
    
    // Cross applications list with live docker container states
    const apps: Application[] = mockApplications.map(app => {
      const container = containers.find(c => c.name === app.container || c.id === app.container);
      let status: Application["status"] = "unknown";
      
      if (container) {
        if (container.state === "running") {
          status = "healthy";
        } else if (container.state === "restarting") {
          status = "degraded";
        } else if (container.state === "exited" || container.state === "stopped") {
          status = "unhealthy";
        }
      } else {
        // If container is not found, default to mock state
        status = app.status;
      }

      return {
        ...app,
        status,
      };
    });

    return NextResponse.json({
      data: apps,
      timestamp: new Date().toISOString(),
      source: "live",
      role,
    });
  } catch (error: any) {
    return NextResponse.json(
      { error: "Internal Server Error", message: error.message },
      { status: 500 }
    );
  }
}
