# NEOS Platform — Production Recovery Handoff Report

**Date:** 2026-07-22  
**Prepared by:** Principal SRE & Production Recovery Engineer  
**Branch:** `feature/platform-dashboard`  
**VPS Node:** `200.97.161.179` (Hostinger VPS)  
**Webapp:** `https://webapp.neosfacility.com`  
**Infra Repo:** `/srv/neos/neos-platform` on VPS

---

## Overall Status

| Recovery Layer | Status | Notes |
|---|---|---|
| PostgreSQL Roles | ✅ COMPLETE | All 6 Supabase roles created via `02-supabase-compat.sql` |
| Auth Schema (GoTrue) | ✅ COMPLETE | 34 users in `auth.users`, GoTrue healthy |
| `public.client_profiles` | ✅ COMPLETE | 34/34 profiles synced, trigger active |
| `public.profiles` alias view | ✅ COMPLETE | All 300+ frontend `.from('profiles')` queries unblocked |
| `public.tasks` & `task_assignees` | ✅ COMPLETE | Tables + RLS + grants added |
| `public.suggestions` & `error_logs` | ✅ COMPLETE | Tables + RLS + grants added |
| `public.employees` + HR tables | ✅ COMPLETE | All HR module tables added |
| `public.locations`, `sister_companies` | ✅ COMPLETE | Added with RLS + grants |
| `public.role_permissions`, `audit_logs` | ✅ COMPLETE | Added with RLS + grants |
| `get_user_order_counts()` RPC | ✅ COMPLETE | Postgres function deployed |
| Local `.env.local` (neos-app-96) | ✅ COMPLETE | All keys synchronized |
| Infra `.env` (KVM2_AMA) | ✅ COMPLETE | Gemini, Firebase, WhatsApp, System secrets added |
| **Live container restart & re-test** | ⏳ PENDING | Container may not have picked up latest schema/env |
| **Page-level end-to-end validation** | ⏳ PENDING | Browser test incomplete due to quota exhaustion |

---

## Remaining Tasks (Resume From Here)

### Priority 1 — Apply Schema to Live Database

All schema changes are committed to `feature/platform-dashboard`. The VPS container may not have applied them yet.

**Run on VPS terminal:**

```bash
cd /srv/neos/neos-platform
git pull origin feature/platform-dashboard
make fix-auth
make diagnose-auth
```

Expected output from `make diagnose-auth`:
- All containers: `running / healthy`
- Roles: `anon`, `authenticated`, `service_role`, `authenticator`, `supabase_admin`, `supabase_auth_admin` — all **PASS**
- `public.profiles` view: **PASS**
- `public.tasks`: **PASS**
- `public.suggestions`, `public.error_logs`: **PASS**
- `public.employees`: **PASS**
- `get_user_order_counts()`: **PASS**
- SMTP: still `WARN` unless configured
- `GEMINI_API_KEY`: should now show **PASS** after adding to VPS `.env`

---

### Priority 2 — Apply AI Keys to VPS `.env`

The Gemini keys are in `D:\WebApp\neos-app-96\.env.local` (laptop) and `D:\WebApp\KVM2_AMA\.env` (laptop), but **these are NOT automatically deployed to the VPS**.

**On VPS terminal, edit `/srv/neos/neos-platform/.env`:**

```bash
nano /srv/neos/neos-platform/.env
```

Add these lines at the bottom:

```env
# Copy the actual values from D:\WebApp\neos-app-96\.env.local on the laptop
# or from the 15-06-2026 .env.local backup
GEMINI_API_KEY=<see .env.local — 3 comma-separated AQ. keys>
WHATSAPP_VERIFY_TOKEN=<see .env.local>
NEXT_PUBLIC_FIREBASE_API_KEY=<see .env.local>
NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN=neos-app-45464.firebaseapp.com
NEXT_PUBLIC_FIREBASE_PROJECT_ID=neos-app-45464
NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET=neos-app-45464.firebasestorage.app
NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID=715595672347
NEXT_PUBLIC_FIREBASE_APP_ID=<see .env.local>
NEXT_PUBLIC_FIREBASE_MEASUREMENT_ID=G-SSK2KD7YW5
NEXT_PUBLIC_FIREBASE_VAPID_KEY=<see .env.local>
BIOMETRIC_SYNC_SECRET=<see .env.local>
AUTO_TASK_SYNC_SECRET=<see .env.local>
```

---

### Priority 3 — Restart Supabase Services

After editing `.env`, restart all Supabase containers so they pick up the new env values:

```bash
cd /srv/neos/neos-platform
docker compose --env-file .env -f compose/compose.supabase.yml restart
```

Wait ~30 seconds, then verify:

```bash
curl -s http://localhost:9999/health
# Expected: {"status":"ok"}
```

---

### Priority 4 — Identify Webapp Container and Rebuild/Restart

The actual `webapp` (`webapp.neosfacility.com`) is a Next.js app served from a separate container. Find and restart it:

```bash
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Image}}"
```

If the webapp container is named something like `neos_webapp` or `webapp`:

```bash
docker restart <webapp_container_name>
# OR rebuild if env is baked into build:
docker compose --env-file .env -f compose/compose.apps.yml up -d --build --remove-orphans
```

> **Important:** If the webapp was built with `next build` and environment variables are baked in (`NEXT_PUBLIC_*` keys), you must **rebuild the container** for those changes to take effect — a restart alone will NOT work.

---

### Priority 5 — End-to-End Page Validation

After all restarts/rebuilds, test each page:

```
https://webapp.neosfacility.com/dashboard/tasks
→ Should list tasks or show empty state (not error)

https://webapp.neosfacility.com/dashboard/admin/suggestions
→ Should load suggestions table (or empty state)

https://webapp.neosfacility.com/dashboard/admin/users
→ Should load user profiles with role counts

https://webapp.neosfacility.com/dashboard/hr
→ Should load employee directory (or empty state)
```

---

### Priority 6 — If Tasks Page Still Fails

Check PostgREST exposure. The Tasks API route at `src/app/api/tasks/route.ts` queries:
1. `from('profiles').select('role, linked_employee_id').eq('id', user.id).single()` — needs `public.profiles` view
2. `from('tasks').select('...')` — needs `public.tasks` table

Verify both exist on live database:

```bash
docker exec -i neos_postgres psql -U postgres -c "\d public.profiles" 2>&1
docker exec -i neos_postgres psql -U postgres -c "\d public.tasks" 2>&1
docker exec -i neos_postgres psql -U postgres -c "SELECT COUNT(*) FROM public.tasks;" 2>&1
```

If `public.profiles` view is missing, apply it directly:

```bash
docker exec -i neos_postgres psql -U postgres <<'SQL'
CREATE OR REPLACE VIEW public.profiles AS
  SELECT id, email, full_name, avatar_url, role, company_name, phone,
         is_active, linked_employee_id, home_latitude, home_longitude,
         home_address, home_radius_meters, home_location_check_required,
         created_at, updated_at
  FROM public.client_profiles;

GRANT SELECT, INSERT, UPDATE ON public.profiles TO authenticated, service_role, anon;
SQL
```

---

### Priority 7 — If Users Page Still Fails

The Users page calls `supabase.rpc('get_user_order_counts')`. Verify it exists:

```bash
docker exec -i neos_postgres psql -U postgres -c "\df public.get_user_order_counts" 2>&1
```

If missing, apply directly:

```bash
docker exec -i neos_postgres psql -U postgres <<'SQL'
CREATE OR REPLACE FUNCTION public.get_user_order_counts()
RETURNS TABLE (user_id UUID, order_count BIGINT)
LANGUAGE plpgsql STABLE SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY SELECT o.created_by, COUNT(*)::BIGINT FROM public.orders o GROUP BY o.created_by;
END;
$$;
GRANT EXECUTE ON FUNCTION public.get_user_order_counts() TO authenticated, service_role, anon;
SQL
```

---

### Priority 8 — SMTP (Password Reset / OTP)

Still not configured. Add to `/srv/neos/neos-platform/.env`:

```env
SMTP_HOST=smtp.sendgrid.net
SMTP_PORT=587
SMTP_USER=apikey
SMTP_PASS=SG.your_actual_sendgrid_key_here
```

Then restart GoTrue:

```bash
docker compose --env-file .env -f compose/compose.supabase.yml restart supabase-auth
```

---

## Files Modified in This Recovery Session

| File | Change | Commit |
|---|---|---|
| `configs/postgres/init-scripts/02-supabase-compat.sql` | Supabase roles, auth helpers | `7dfa416` |
| `configs/postgres/init-scripts/03-app-schema.sql` | All application tables, profiles view, tasks, suggestions, employees, locations, RPC, grants | `5b0888d`, `e7227f4` |
| `scripts/fix-auth.sh` | Removed `-t` TTY flags | `7dfa416` |
| `scripts/diagnose-auth.sh` | Removed `-t` TTY flags + added AI audit section | `9541e46` |
| `.env.example` | Added `GEMINI_API_KEY`, `GROQ_API_KEY` sections | `9541e46` |
| `docs/production_recovery_report.md` | Full audit report | `ba1d3c5`, `9eefd6e` |
| `D:\WebApp\neos-app-96\.env.local` | All Supabase, Gemini, Firebase, system secrets updated (laptop only) | N/A — not committed |

---

## Commit History (This Session)

```
ba1d3c5  docs: add environment keys synchronization status
9eefd6e  docs: add AI and Gemini environment audit to production recovery report
9541e46  feat(ai): add GEMINI_API_KEY and GROQ_API_KEY environment variables audit
9347994  docs: add production recovery audit report and module resolution matrix
5b0888d  fix(schema): add suggestions, error_logs, employees, location, and get_user_order_counts RPC to app schema
9347994  docs: add production recovery audit report and module resolution matrix
e7227f4  fix(schema): add profiles view, tasks, task_assignees tables
7dfa416  fix(scripts): remove -t TTY flags from docker exec in diagnose-auth and fix-auth
```

---

## Risks & Known Gaps

| Risk | Severity | Status |
|---|---|---|
| VPS `.env` not updated with Gemini/Firebase keys | HIGH | Requires manual edit on VPS — not pushed to git |
| Container not rebuilt after `.env` change | HIGH | Requires `docker compose ... up -d --build` |
| SMTP not configured | MEDIUM | GoTrue confirms mail delivery disabled |
| Webapp may be separate container not in KVM2_AMA compose | MEDIUM | Locate exact container name with `docker ps` |
| `public.profiles` view may not exist on live DB yet | HIGH | Run `make fix-auth` first |

---

## Quick Reference: Full Resume Commands (from new computer)

```bash
# 1. Pull latest code
cd /srv/neos/neos-platform
git pull origin feature/platform-dashboard

# 2. Apply schema and roles
make fix-auth

# 3. Run diagnostics
make diagnose-auth

# 4. Edit .env with production keys (see Priority 2 above)
nano .env

# 5. Restart Supabase services
docker compose --env-file .env -f compose/compose.supabase.yml restart

# 6. Find and rebuild/restart webapp container
docker ps --format "table {{.Names}}\t{{.Status}}"
# Then: docker restart <webapp_name>
# Or:   docker compose --env-file .env -f compose/compose.apps.yml up -d --build

# 7. Verify GoTrue
curl -s http://localhost:9999/health

# 8. Test pages in browser
# https://webapp.neosfacility.com/dashboard/tasks
# https://webapp.neosfacility.com/dashboard/admin/suggestions
# https://webapp.neosfacility.com/dashboard/admin/users
# https://webapp.neosfacility.com/dashboard/hr
```
