# NEOS Platform — Application Audit Log

**Last Updated:** 2026-07-25  
**Audit Target:** `https://test.neosfacility.com`  
**Environment:** Hostinger VPS (Docker / Traefik / Supabase)

---

## 1. Executive Summary

This document records the comprehensive page-by-page audit of the NEOS Platform web application accessible via the sidebar and nested sub-menus. For each page, runtime status, browser console errors, failed network calls, API failure payloads, toast notifications, screenshot evidence, and root cause analyses are captured.

---

## 2. Sidebar Application Audit Matrix

| Menu Name | Route | Status | Browser Console Errors | Failed Network Calls / API Failures | Toast Notifications | Screenshot Evidence | Primary Root Cause / Issue Summary |
|---|---|---|---|---|---|---|---|
| **Dashboard** | `/dashboard` | 🟢 PASS | None | None | None | `audit_dashboard_1784990848094_1784990930996.png` | Loads cleanly with metrics and task summary widgets. |
| **Operations Workspace** | `/dashboard/operations` | 🟢 PASS | None | None | None | `audit_operations_workspace_1784990848094_1784990984647.png` | Control panel overview operational. |
| **GeM Command** | `/dashboard/gem` | 🟢 PASS | None | None | None | `audit_gem_command_1784990848094_1784991054496.png` | GeM procurement workspace operational. |
| **Tasks** | `/dashboard/tasks` | 🟢 PASS | None | None | None | `tasks_list_final_1784954242370.png` | 61 tasks loaded, full CRUD (Create, Edit, Delete) verified. |
| **Orders** | `/dashboard/orders` | 🟢 PASS | None | None | None | `orders_list_verified.png` | Verified on VPS, awaiting final owner confirmation. |
| **Users** | `/dashboard/admin/users` | 🔴 FAIL | `Error fetching users/orders: Object` (`TypeError: Failed to fetch`) | POST `https://supabase.neosfacility.com/rest/v1/rpc/get_user_order_counts` (CORS Block) | `Failed to load users 🚨` | `audit_users_page_1784991934380.png` | **CORS / Preflight Header Mismatch**: Browser blocks RPC POST call because PostgREST injects `content-profile: public` header which is not listed in Supabase server's allowed CORS headers (`Access-Control-Allow-Headers`). GET requests using `accept-profile` pass while RPC POST fails, causing Promise.all to throw and UI to show 0 users. |
| **Suggestions & Errors** | `/dashboard/admin/suggestions` | 🔴 FAIL | `Error: Failed to fetch suggestions` | GET `https://test.neosfacility.com/api/suggestions` → **HTTP 500** (`Could not find a relationship between 'suggestions' and 'assigned_developer_id' in schema cache`) | `Failed to load suggestions backlog` | `audit_suggestions_page_1784992017152.png` | **PostgREST Foreign Key Relationship Missing**: Database column `suggestions.assigned_developer_id` lacks foreign key constraint to `profiles.id`. Joined PostgREST query in `/api/suggestions` (`profiles:assigned_developer_id(*)`) crashes with HTTP 500. *(Sub-tabs 'AI Quality Score' and 'Error Logs' load successfully)*. |

---

## 3. Failure Breakdown & Diagnostic Details

### 3.1 Users Page (`/dashboard/admin/users`)
* **Behavior:** Page UI shell renders, but displays **0 Total Users** and **"No users found"**.
* **Diagnostic Evidence:**
  - `Promise.all` in `fetchProfiles()` executes 3 queries: `profiles` (GET), `role_permissions` (GET), and `rpc/get_user_order_counts` (POST).
  - The browser preflight / fetch to `https://supabase.neosfacility.com/rest/v1/rpc/get_user_order_counts` fails with `TypeError: Failed to fetch`.
  - OPTIONS preflight response from Supabase server specifies `Access-Control-Allow-Headers: apikey,content-type,authorization,accept-profile,...` but **omits `content-profile`**.
* **Root Cause Group:** **Supabase / PostgREST CORS Header Configuration**.

### 3.2 Suggestions Page (`/dashboard/admin/suggestions`)
* **Behavior:** Main layout loads, but Backlog tab renders empty ("No suggestions matching filters") and pops error toast.
* **Diagnostic Evidence:**
  - `/api/suggestions` endpoint returns `{"status":"error","message":"Could not find a relationship between 'suggestions' and 'assigned_developer_id' in the schema cache"}` with HTTP status 500.
  - PostgreSQL schema inspection shows `assigned_developer_id` UUID column exists without foreign key reference `REFERENCES public.profiles(id)`.
* **Root Cause Group:** **PostgreSQL Foreign Key / PostgREST Schema Cache**.

---

## 4. Audit Plan & Remaining Sidebar Coverage

Next batch of sidebar pages to audit:
- Business Intelligence (`/business-intelligence/dashboard`)
- Clients (`/dashboard/clients`)
- CRM (`/dashboard/crm/stage-tracking`)
- Performance (`/dashboard/performance`)
- Documents (`/dashboard/documents`)
- Approvals (`/dashboard/approvals`)
- Operations Control Tower (`/dashboard/operations/control-tower`)
- Items (`/dashboard/items`)
- Inventory & Assembly (`/dashboard/inventory`)
- Field Operations (EFOP) (`/dashboard/operations/wes`)
- Order Fulfillment (`/dashboard/operations/fulfillment`)
- Revenue & Collections (`/dashboard/operations/revenue-realization`)
- Delivery Portal (`/dashboard/operations/delivery`)
- Fleet Management (`/dashboard/operations/fleet`)
- Procurement (`/dashboard/procurement`)
- Asset Management (`/dashboard/assets`)
- Categories (`/dashboard/categories`)
- Vendors (`/dashboard/vendors`)
- Sister Companies (`/dashboard/sister-companies`)
- Payroll (`/dashboard/hr/payroll`)
- Attendance (`/dashboard/field-tracking`)
- Leaves (`/dashboard/leaves`)
- Resource & Costs (`/dashboard/resource-costs`)
- Payment Compliance (`/dashboard/payment-compliance`)
- Recoverable Assets (`/dashboard/refundable-assets`)
- Reports (`/dashboard/admin/reports`)
- Payments (`/dashboard/admin/payments`)
- Sessions (`/dashboard/admin/sessions`)
- Permission & Access (EAPC) (`/dashboard/admin/eapc`)
- Integration & APIs (EIAP) (`/dashboard/admin/eiap`)
- Org Hierarchy (`/dashboard/admin/hierarchy`)
- WhatsApp (`/dashboard/admin/whatsapp`)
- Task Labels (`/dashboard/admin/labels`)
- Automations (`/dashboard/admin/automations`)
- Business Rules (BRAP) (`/dashboard/admin/brap`)
- Master Data (MDM) (`/dashboard/admin/mdm`)
- Data Quality (DQCE) (`/dashboard/admin/dqce`)
- Help Center (EKR) (`/dashboard/help-center`)
- Restore Center (`/dashboard/admin/restore`)
- Audit Logs (`/dashboard/admin/audit-logs`)
- Productivity (`/dashboard/admin/productivity`)
- Configuration (`/dashboard/admin/configuration`)
- Attendance Rules (`/dashboard/admin/attendance-rules`)
- EFOP Config (`/dashboard/operations/efop-config`)
- System & UI Health (`/dashboard/admin/ui-health`)
- Profile (`/dashboard/profile`)
