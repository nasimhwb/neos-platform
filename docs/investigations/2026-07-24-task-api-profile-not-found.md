# Investigation Report: `/api/tasks` Profile Not Found Error

**Date:** 2026-07-24  
**Engineer / AI:** Antigravity (Google DeepMind Team)  
**Branch:** `feature/platform-dashboard`  
**Target Environment:** Hostinger VPS Staging (`https://test.neosfacility.com`)  

---

## 1. Problem Statement

Calling `GET /api/tasks?userId=05a7cbdc-a7e3-47aa-afd5-fcc57461f3ae` on `https://test.neosfacility.com` returns `HTTP 404 Not Found` with body:
```json
{"error": "Profile not found"}
```
Even though profile `05a7cbdc-a7e3-47aa-afd5-fcc57461f3ae` (`tester@neosfacility.com`) exists in the self-hosted PostgreSQL `public.profiles` database view on the VPS.

---

## 2. Timeline & Investigation Steps

1. **Self-Hosted PostgreSQL Query**: Directly queried PostgREST at `https://supabase.neosfacility.com/rest/v1/profiles?id=eq.05a7cbdc-a7e3-47aa-afd5-fcc57461f3ae`.
   - Result: `HTTP 200 OK`. Record found (`role: admin`, `linked_employee_id: C1134`).
2. **Next.js Route Handler Inspection** (`src/app/api/tasks/route.ts`):
   ```typescript
   const { data: profile, error: profileError } = await supabaseAdmin
     .from('profiles')
     .select('role, linked_employee_id')
     .eq('id', user.id)
     .single();

   if (profileError || !profile) {
     return NextResponse.json({ error: 'Profile not found' }, { status: 404 });
   }
   ```
3. **Environment Isolation Analysis**:
   - `supabaseAdmin` uses `NEXT_PUBLIC_SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY`.
   - The web app container running on the VPS was built with `NEXT_PUBLIC_SUPABASE_URL=https://epcbqpkosqucugfbmveo.supabase.co` (Cloud Supabase).
   - User `05a7cbdc-a7e3-47aa-afd5-fcc57461f3ae` does not exist in Cloud Supabase, so `supabaseAdmin` returns `profileError`, causing the handler to output `404 Profile not found`.
4. **Middleware Cookie Routing Analysis**:
   - `@supabase/ssr` computes auth cookie names dynamically from `NEXT_PUBLIC_SUPABASE_URL`.
   - When configured for Cloud Supabase, middleware expects `sb-epcbqpkosqucugfbmveo-auth-token`.
   - Requests with self-hosted tokens fail authentication in middleware, causing `307 Redirect` to `/login`.

---

## 3. Root Cause

1. **Build-Time Constant Baking**: Next.js bakes `NEXT_PUBLIC_*` variables into compiled bundle chunks during `next build`. Re-running `docker restart` reuses cached container layers containing stale Cloud Supabase URLs.
2. **Environment Synchronization Blocker**: The running container requires a clean rebuild (`docker compose build --no-cache dashboard`) using self-hosted VPS `.env` values.

---

## 4. Remediation & Deployment Runbook

Run on VPS terminal:
```bash
# 1. Update /srv/neos/neos-platform/.env
NEXT_PUBLIC_PLATFORM_PROVIDER=self-hosted
NEXT_PUBLIC_SUPABASE_URL=https://supabase.neosfacility.com
SUPABASE_URL=https://supabase.neosfacility.com

# 2. Rebuild Next.js container without cache
cd /srv/neos/neos-platform
docker compose --env-file .env -f compose/compose.apps.yml build --no-cache dashboard

# 3. Restart container without touching database/infra stack
docker compose --env-file .env -f compose/compose.apps.yml up -d --no-deps dashboard

# 4. Verify running process environment
docker exec dashboard printenv | grep SUPABASE
```

---

## 5. Verification Checklist

- [x] Empirical PostgREST probe verified record exists in self-hosted DB.
- [x] Code handler path & middleware cookie logic traced.
- [x] Documentation & runbook committed to repository.
- [ ] Container rebuild on VPS.
- [ ] End-to-End browser task CRUD verification.
