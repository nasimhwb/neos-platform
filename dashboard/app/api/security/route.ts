import { NextRequest, NextResponse } from "next/server";
import { SecurityService } from "@/lib/services/SecurityService";
import { SSLService } from "@/lib/services/SSLService";

export async function GET(request: NextRequest) {
  const role = request.headers.get("x-user-role") || "Read Only";

  try {
    const { firewallRules, securityEvents, sshStatus, openPorts, blockedIps, source: secSource } = 
      await SecurityService.getSecurityData();
      
    const { certs } = await SSLService.getCertificates();

    return NextResponse.json({
      data: {
        firewallRules,
        securityEvents,
        sshStatus,
        openPorts,
        blockedIps,
        certs,
      },
      timestamp: new Date().toISOString(),
      source: secSource,
      role,
    });
  } catch (error: any) {
    return NextResponse.json(
      { error: "Internal Server Error", message: error.message },
      { status: 500 }
    );
  }
}
