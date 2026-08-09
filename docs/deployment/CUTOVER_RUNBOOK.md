# Production Cutover Runbook

**Date:** 2026-07-24  
**Scope:** Zero-Data-Loss Cutover from Production Cloud Supabase to Hostinger VPS Self-Hosted Stack  

---

## 1. Pre-Cutover Verification Matrix

- [x] All Supabase database schema migrations applied (`01-init.sql`, `02-supabase-compat.sql`, `03-app-schema.sql`).
- [x] Web application container build configuration updated with build ARGs.
- [ ] Staging VPS environment validated for 2 consecutive days with 0 critical errors.

---

## 2. Sequence of Data Migration

To preserve foreign key constraints and prevent orphan records, data must be restored in exact dependency order:

1. `auth.users` and `auth.identities` (GoTrue Auth)
2. `public.client_profiles` and `public.profiles`
3. `public.sister_companies` and `public.locations`
4. `public.employees` and `public.departments`
5. `public.role_permissions` and `public.system_roles`
6. `public.clients` and `public.vendors`
7. `public.orders` and `public.order_items`
8. `public.tasks` and `public.task_assignees`
9. `public.documents` and `public.attachments`
10. `public.activity_logs`, `public.complaints`, `public.error_logs`, `public.notifications`
