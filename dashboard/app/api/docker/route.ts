import { NextResponse } from "next/server";
import { mockDockerStatus, mockContainers, mockNetworks, mockVolumes } from "@/lib/mock-data";

export async function GET() {
  return NextResponse.json({
    data: { status: mockDockerStatus, containers: mockContainers, networks: mockNetworks, volumes: mockVolumes },
    timestamp: new Date().toISOString(),
    source: "mock",
  });
}
