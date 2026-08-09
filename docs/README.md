# NEOS Platform — Central Documentation Portal & Master Index

Welcome to the NEOS Platform single source of truth repository wiki. All operational, architectural, investigation, and deployment documentation is maintained within this directory.

---

## 1. Documentation Index

### 🏛️ Architecture (`docs/architecture/`)
* 📐 [SYSTEM_ARCHITECTURE.md](file:///d:/WebApp/KVM2/docs/architecture/SYSTEM_ARCHITECTURE.md) — High-level multi-tenant microservice topology & component diagram.
* 🔐 [AUTHENTICATION.md](file:///d:/WebApp/KVM2/docs/architecture/AUTHENTICATION.md) — Supabase GoTrue JWT flow, RLS policies, and key specifications.

### 🚀 Deployment & Migration (`docs/deployment/`)
* 🖥️ [VPS_STAGING.md](file:///d:/WebApp/KVM2/docs/deployment/VPS_STAGING.md) — Hostinger VPS staging deployment guide & quick redeploy commands.
* 🔄 [PRODUCTION_MIGRATION.md](file:///d:/WebApp/KVM2/docs/deployment/PRODUCTION_MIGRATION.md) — Zero-data-loss cutover & table dependency migration sequence.
* 📋 [CUTOVER_RUNBOOK.md](file:///d:/WebApp/KVM2/docs/deployment/CUTOVER_RUNBOOK.md) — Step-by-step production cutover runbook.
* 🛡️ [DISASTER_RECOVERY_PLAN.md](file:///d:/WebApp/KVM2/docs/deployment/DISASTER_RECOVERY_PLAN.md) — Emergency rollback & backup recovery plan.

### 🔍 Investigations & Engineering Journal (`docs/investigations/`)
* 📓 [INVESTIGATION_LOG.md](file:///d:/WebApp/KVM2/docs/investigations/INVESTIGATION_LOG.md) — Chronological engineering journal of all technical probes & root causes.
* 🐞 [2026-07-24-task-api-profile-not-found.md](file:///d:/WebApp/KVM2/docs/investigations/2026-07-24-task-api-profile-not-found.md) — Deep dive into `/api/tasks` 404 profile lookup & build ARG resolution.
* 🐳 [2026-07-24-running-container-db-investigation.md](file:///d:/WebApp/KVM2/docs/investigations/2026-07-24-running-container-db-investigation.md) — Runtime environment variable isolation probe.

### 📊 Operations & Project Status (`docs/operations/`)
* 📈 [PROJECT_STATUS.md](file:///d:/WebApp/KVM2/docs/operations/PROJECT_STATUS.md) — Current sprint status, module verification matrix, and readiness %.
* 📝 [CHANGELOG.md](file:///d:/WebApp/KVM2/docs/operations/CHANGELOG.md) — Chronological record of all code & infrastructure updates.
* 🚨 [KNOWN_ISSUES.md](file:///d:/WebApp/KVM2/docs/operations/KNOWN_ISSUES.md) — Active, pending, and resolved issue tracking table.

### 📑 Verification & Audit Reports (`docs/reports/`)
* 🌐 [APPLICATION_VERIFICATION_REPORT.md](file:///d:/WebApp/KVM2/docs/reports/APPLICATION_VERIFICATION_REPORT.md) — End-to-End application verification suite results.
* 🔒 [PRODUCTION_SECURITY_AUDIT_REPORT.md](file:///d:/WebApp/KVM2/docs/reports/PRODUCTION_SECURITY_AUDIT_REPORT.md) — Infrastructure security audit & hardening report.

---

## 2. Current Project State

* **Active Branch**: `feature/platform-dashboard`
* **Target VPS Node**: `200.97.161.179` (Hostinger VPS)
* **Staging Endpoint**: `https://test.neosfacility.com`
* **Staging Readiness**: 🟢 **100% (Code Fix Applied)**
* **Latest Fix**: Injected `ARG NEXT_PUBLIC_SUPABASE_URL` and `ARG NEXT_PUBLIC_PLATFORM_PROVIDER` into `dashboard/Dockerfile` and `compose.dashboard.yml`.
