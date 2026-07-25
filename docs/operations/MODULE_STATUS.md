# NEOS Platform — Module Status Matrix

**Last Updated:** 2026-07-25  
**Active Branch:** `feature/platform-dashboard` (neos-platform) / `master` (neos-app)

---

## 1. Module Verification Summary

| Module | Status | Verification Detail | Last Audit Result |
|---|---|---|---|
| **Authentication** | 🟢 Operational | GoTrue JWT issued, browser login succeeds with `tester@neosfacility.com`. | PASS |
| **Dashboard** | 🟢 Operational | Overview dashboard loads metrics and pending task widgets cleanly. | PASS |
| **Operations Workspace** | 🟢 Operational | Control panel workspace overview functional. | PASS |
| **GeM Command** | 🟢 Operational | GeM procurement workspace functional. | PASS |
| **Tasks Module** | 🟢 Operational | Deployed on VPS; 61 tasks loaded, Create / Edit / Delete CRUD verified. | PASS |
| **Orders & Operations** | 🟢 Verified (Pending Confirmation) | Table `public.orders` populated with seeds; verified on staging. | PASS |
| **User Management** | 🔴 Action Required | UI route `/dashboard/admin/users` loads 0 users due to CORS preflight header mismatch on RPC call. | FAIL (API / CORS) |
| **Suggestions & Errors** | 🔴 Action Required | UI route `/dashboard/admin/suggestions` backlog fails with HTTP 500 (missing FK constraint on `assigned_developer_id`). | FAIL (Schema FK) |

---

## 2. Infrastructure & Service Status

* **Traefik Load Balancer**: 🟢 Healthy (`/api/health` returning HTTP 200)
* **PostgreSQL / PostgREST**: 🟢 Healthy (`neos_postgres` container active)
* **Supabase Auth (GoTrue)**: 🟢 Healthy (`neos_supabase_auth` container active)
* **Next.js Dashboard App**: 🟢 Healthy (`neos_dashboard` container active)
* **Next.js Main App**: 🟢 Healthy (`neos_app` container active)
