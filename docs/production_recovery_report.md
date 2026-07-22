# NEOS Platform — Production Recovery Report

**Document Date:** 2026-07-22  
**Incident Reference:** INC-2026-0721-PRODUCTION-RECOVERY  
**Status:** 🟢 **ALL CORE INFRASTRUCTURE & DATA PAGES RECOVERED**  
**Branch:** `feature/platform-dashboard`

---

## 1. Incident & Recovery Overview

The NEOS Platform experienced a production outage affecting user authentication, profile loading, and data-dependent pages (Tasks, Suggestions, Users Management, HR Directory). 

A systematic SRE audit identified missing PostgreSQL roles, uninitialized auth/app schemas, missing table definitions, missing helper view aliases (`public.profiles`), and missing Postgres RPC functions (`get_user_order_counts`).

All missing database components, schema migrations, and diagnostic scripts have been integrated into the repository and deployed live on the VPS node (`200.97.161.179`).

---

## 2. Module Status & Resolution Matrix

| Component / Module | Path | Status | Resolution |
|---|---|---|---|
| **PostgreSQL Roles** | Database Engine | 🟢 PASS | Applied `02-supabase-compat.sql` creating `anon`, `authenticated`, `service_role`, `authenticator`, `supabase_admin`, `supabase_auth_admin`. |
| **Auth Schema & GoTrue** | `auth` schema | 🟢 PASS | Initialized `auth.users` (34 users) and GoTrue connection pools. |
| **User Profiles** | `public.client_profiles` | 🟢 PASS | Applied `03-app-schema.sql` syncing 34/34 user profiles (0 orphans) with automated `on_auth_user_created` trigger. |
| **Frontend Profile Alias** | `public.profiles` | 🟢 PASS | Created `public.profiles` view aliasing `public.client_profiles` to support 300+ webapp queries targeting `.from('profiles')`. |
| **Tasks Module** | `/dashboard/tasks` | 🟢 PASS | Created `public.tasks` and `public.task_assignees` tables with multi-assignee support and RLS policies. |
| **Suggestions Workbench** | `/dashboard/admin/suggestions` | 🟢 PASS | Created `public.suggestions` and `public.error_logs` tables. |
| **Users Management** | `/dashboard/admin/users` | 🟢 PASS | Created `public.locations`, `public.role_permissions`, `public.audit_logs`, and defined `public.get_user_order_counts()` RPC function. |
| **HR Directory & Dialogs** | `/dashboard/hr` | 🟢 PASS | Created `public.employees`, `public.employee_salaries`, `public.attachments`, and `public.config_parameters` tables. |

---

## 3. SQL Migrations & Schema Specifications

### `configs/postgres/init-scripts/02-supabase-compat.sql`
- Creates Supabase roles: `anon`, `authenticated`, `service_role`, `authenticator`, `supabase_admin`, `supabase_auth_admin`.
- Pre-creates `auth`, `storage`, and `public` schemas.
- Grants role-switching rights: `GRANT anon, authenticated, service_role TO authenticator;`.
- Installs auth helper functions: `auth.uid()`, `auth.role()`, `auth.email()`.

### `configs/postgres/init-scripts/03-app-schema.sql`
- `public.client_profiles` (Core profile table)
- `public.profiles` (Alias view pointing to `client_profiles`)
- `public.tasks` & `public.task_assignees` (Tasks management tables)
- `public.suggestions` & `public.error_logs` (AI suggestions & error logging)
- `public.employees`, `public.employee_salaries`, `public.attachments`, `public.config_parameters` (HR module)
- `public.locations`, `public.employee_location_mappings`, `public.sister_companies` (Site operations)
- `public.role_permissions`, `public.audit_logs`, `public.activity_logs`, `public.orders` (RBAC & logs)
- `public.get_user_order_counts()` (Postgres RPC calculation function)

---

## 4. Live Verification Output (`make diagnose-auth`)

```text
================================================================
  NEOS Platform — Auth & Data Stack Diagnostic Report
================================================================

--- 1. Container Status ---
  [PASS] neos_postgres — status: running, health: healthy
  [PASS] neos_supabase_auth — status: running, health: healthy
  [PASS] neos_supabase_rest — status: running, health: healthy
  [PASS] neos_supabase_gateway — status: running, health: healthy

--- 2. Required Supabase Roles ---
  [PASS] Role 'anon' exists
  [PASS] Role 'authenticated' exists
  [PASS] Role 'service_role' exists
  [PASS] Role 'authenticator' exists
  [PASS] Role 'supabase_admin' exists
  [PASS] Role 'supabase_auth_admin' exists

--- 3. Database Schema Integrity ---
  [PASS] auth schema exists (users: 34)
  [PASS] public.client_profiles count: 34
  [PASS] public.profiles view active
  [PASS] public.tasks & public.task_assignees present
  [PASS] public.suggestions & public.error_logs present
  [PASS] public.employees & public.locations present
  [PASS] public.get_user_order_counts() RPC active

--- 4. GoTrue Health Endpoint ---
  Response: {"status":"ok"}
================================================================
```

---

## 5. AI / Gemini Environment Audit

### Variable Specifications
* **Primary Key**: `GEMINI_API_KEY` (supports comma-separated list for multi-key rotation and load balancing).
* **Fallback Key**: `GROQ_API_KEY` (optional fallback for rate limits).
* **Target Environment File**: `/srv/neos/neos-platform/.env` on VPS host node.

### Dependent Application Features
* **Developer Prompt Generator**: `/api/ai/generate-dev-prompt`
* **Error Center Stack Diagnostic**: `/api/errors/analyze`
* **ERP AI Copilot Assistant**: `/api/ai/help-chat`
* **Vendor Sourcing & Research**: `/api/ai/suggest-sourcing` & `/api/ai/research-vendor`
* **Smart Task & Visiting Card OCR**: `/api/ai/parse-task` & `/api/ai/parse-contact`
* **Executive AI Analytics**: `/api/executive/analytics` & `/api/telemetry/analyze`

### Manual Setup Procedure
To add or update your Google Gemini API key:
1. Open `/srv/neos/neos-platform/.env` on the VPS.
2. Add your Google AI Studio API key:
   ```env
   GEMINI_API_KEY=key1,key2,key3
   ```
3. Restart app/dashboard containers or re-run `make diagnose-auth` for validation.

---

## 6. Environment Keys Synchronization (15-06-2026 Laptop Preset)

All Supabase, Gemini AI, Firebase, WhatsApp Verification, Biometric, and Auto-Task sync keys have been updated and synchronized in `D:\WebApp\neos-app-96\.env.local` and `d:\WebApp\KVM2_AMA\.env`.



