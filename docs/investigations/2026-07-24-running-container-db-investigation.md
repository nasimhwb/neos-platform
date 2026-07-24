# Investigation Report: Running Web App Container Database Connection

**Date:** 2026-07-24  
**Target Host:** Hostinger VPS (`200.97.161.179`)  
**Staging Web Application:** `https://test.neosfacility.com`  
**Self-Hosted Supabase:** `https://supabase.neosfacility.com`  

---

## 1. Problem Statement

Calling `GET /api/tasks` on `https://test.neosfacility.com` returns `HTTP 404 Not Found` with payload:
```json
{"error": "Profile not found"}
```
Even though profile `05a7cbdc-a7e3-47aa-afd5-fcc57461f3ae` (`tester@neosfacility.com`) exists in the self-hosted PostgreSQL database on the VPS.

---

## 2. Empirical Verification & Evidence

### PostgREST Direct Query to VPS Database
* **Request**: `GET https://supabase.neosfacility.com/rest/v1/profiles?id=eq.05a7cbdc-a7e3-47aa-afd5-fcc57461f3ae`
* **Headers**: `apikey: <SELF_HOSTED_ANON_KEY>`, `Authorization: Bearer <SELF_HOSTED_SERVICE_ROLE_KEY>`
* **Response**: `HTTP 200 OK`
```json
[
  {
    "id": "05a7cbdc-a7e3-47aa-afd5-fcc57461f3ae",
    "full_name": "Tester Admin",
    "role": "admin",
    "email": "tester@neosfacility.com",
    "linked_employee_id": "C1134",
    "is_active": true
  }
]
```

### Next.js API Route Query (`GET /api/tasks`)
* **Request**: `GET https://test.neosfacility.com/api/tasks`
* **Response**: `HTTP 404 Not Found`
* **Payload**: `{"error": "Profile not found"}`

---

## 3. Root Cause

1. **Stale Process Environment in Web App Container**: The running Next.js application container was initialized with cloud Supabase parameters (`NEXT_PUBLIC_SUPABASE_URL=https://epcbqpkosqucugfbmveo.supabase.co`).
2. **Missing Profile in Cloud Database**: User `05a7cbdc-a7e3-47aa-afd5-fcc57461f3ae` does not exist in Cloud Supabase. Therefore, `supabaseAdmin.from('profiles').select(...).eq('id', user.id).single()` fails with `PGRST116`, triggering early exit in `src/app/api/tasks/route.ts` with HTTP 404.
3. **Build-Time Variable Invalidation**: `NEXT_PUBLIC_*` environment variables are baked into static/SSR chunks during `next build`. Re-triggering a simple `docker restart` without `docker compose build --no-cache dashboard` retains stale endpoints.

---

## 4. Remediation Steps Required

Execute on VPS host terminal:
```bash
cd /srv/neos/neos-platform
docker compose --env-file .env -f compose/compose.apps.yml build --no-cache dashboard
docker compose --env-file .env -f compose/compose.apps.yml up -d --no-deps dashboard
```

---

## 5. Verification Checklist

- [x] Verified user profile exists in VPS PostgREST database.
- [x] Isolated container process environment variable mismatch.
- [ ] Rebuild web application container with self-hosted environment keys.
- [ ] Verify `HTTP 200 OK` on `GET https://test.neosfacility.com/api/tasks`.
- [ ] End-to-End Tasks CRUD verification in Chrome browser.
