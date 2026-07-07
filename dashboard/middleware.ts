import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";

const VALID_ROLES = ["Super Admin", "Platform Admin", "Developer", "Auditor", "Read Only"];

export function middleware(request: NextRequest) {
  // Only intercept API endpoints
  if (request.nextUrl.pathname.startsWith("/api")) {
    const requestHeaders = new Headers(request.headers);
    
    // 1. Resolve role from header, cookie, or query parameter (for easy demo/mocking)
    let role = request.headers.get("x-user-role") || 
               request.cookies.get("user-role")?.value || 
               request.nextUrl.searchParams.get("role");
               
    if (!role || !VALID_ROLES.includes(role)) {
      role = "Read Only"; // Default fallback
    }

    // 2. Set resolved role header for downstream API handlers
    requestHeaders.set("x-user-role", role);

    // 3. Implement permission middleware checks (Write/Update operations)
    const isMutatingAction = ["POST", "PUT", "DELETE", "PATCH"].includes(request.method);
    
    if (isMutatingAction) {
      // Rejects mutations for Read Only or Auditor roles
      if (role === "Read Only" || role === "Auditor") {
        return NextResponse.json(
          {
            error: "Forbidden",
            message: `Insufficient permissions. Role '${role}' is not allowed to perform administrative modifications.`,
            code: 403,
          },
          { status: 403 }
        );
      }
    }

    // Continue request chain
    return NextResponse.next({
      request: {
        headers: requestHeaders,
      },
    });
  }

  return NextResponse.next();
}

// Apply middleware to API routes only
export const config = {
  matcher: "/api/:path*",
};
