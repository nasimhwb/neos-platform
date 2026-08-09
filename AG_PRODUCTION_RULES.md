# AG PRODUCTION OPERATING RULES
## NEOS Platform / NEOS App Production Environment

==============================================================================
CRITICAL MANDATE:
This repository and infrastructure govern a LIVE PRODUCTION ENVIRONMENT.
All AI agents, automation tools, and developers operating on this codebase
or connected infrastructure MUST strictly comply with these rules.
==============================================================================

---

### PRODUCTION RULE #0 — PULL BEFORE ANY ACTION

**PULL FIRST BEFORE EXECUTING ANY PROMPT OR RUNNING ANY TASK.**

Before analyzing, creating, editing files, running scripts, or proposing any changes:
1. The agent MUST execute `git pull` (or inspect `git status` and pull latest data from GitHub).
2. Never operate on stale repository state.
3. Ensure local and remote synchronization before executing user instructions.

```bash
# Mandatory first step in any agent invocation:
git status
git pull
```

---

### PRODUCTION RULE #1 — READ BEFORE CHANGE

**ALWAYS READ DOCUMENTATION BEFORE TOUCHING PRODUCTION.**

Before proposing, modifying, or deploying any code or infrastructure configuration, read:
- `PRODUCTION_STATE.md` (Authoritative live production state)
- `PRODUCTION_CHANGELOG.md` (Operational history and verified changes)
- `PRODUCTION_DO_NOT_TOUCH.md` (Explicit safety rules & forbidden actions)
- `AG_PRODUCTION_RULES.md` (This operational philosophy document)

---

### PRODUCTION RULE #2 — NEVER GUESS

**NEVER GUESS INFRASTRUCTURE DETAILS.**

Never guess or assume:
- Container names
- Docker networks
- Database locations / schemas / table structures
- Database names and roles
- Storage locations and directory layouts
- Storage bucket names and object counts
- Domain names, routing rules, and subdomains
- DNS records and resolution
- Traefik dynamic routing and middleware configuration
- Docker Compose files and active compose project names
- Environment variables and configuration sourcing
- Secret values or token formats
- Docker volumes and persistent mount paths
- Active release directory vs inactive release directories
- Active deployment method and CI/CD workflow

**Always verify directly against the live server or codebase.**

---

### PRODUCTION RULE #3 — READ-ONLY FIRST

**WHEN INVESTIGATING AN INCIDENT OR AUDITING THE SYSTEM:**

Follow this strict 7-step investigative sequence:
1. **Inspect** (Read configuration, query status, inspect logs without modifying state)
2. **Measure** (Capture latency, error rates, resource utilization, HTTP status codes)
3. **Diagnose** (Trace request paths, pinpoint root cause using empirical evidence)
4. **Document** (Record observations, symptoms, traces, and hypothesis in logs)
5. **Propose** (Draft non-destructive resolution plan and obtain user approval)
6. **Change** (Execute minimal, isolated, and targeted changes)
7. **Verify** (Perform end-to-end tests, inspect health checks and logs post-change)

*Do NOT modify production merely because something looks unusual or undocumented.*

---

### PRODUCTION RULE #4 — NO DESTRUCTIVE ACTION WITHOUT APPROVAL

**NEVER EXECUTE DESTRUCTIVE ACTIONS WITHOUT EXPLICIT WRITTEN APPROVAL.**

If an operation has the potential to delete, reset, overwrite, migrate, recreate, prune, or invalidate production data, persistent volumes, database tables, storage objects, secrets, or routing configurations:

**STOP IMMEDIATELY AND REQUEST USER APPROVAL.**

---

### PRODUCTION RULE #5 — BACKUP BEFORE RISK

**BEFORE ANY RISKY OPERATION:**

1. Identify existing backup.
2. Verify backup integrity and timestamp.
3. Document explicit rollback procedure.
4. Only then proceed with the change.

*If no usable backup exists, report this finding immediately and do not proceed.*

---

### PRODUCTION RULE #6 — VERIFY AFTER CHANGE

**AFTER EVERY PRODUCTION CHANGE:**

1. Check container status: `docker ps` (verify all expected containers are `Up (healthy)`).
2. Check service health endpoints (`/api/health`, `/auth/v1/health`, etc.).
3. Check application logs for runtime exceptions or error spikes (`docker logs --tail 100 <container>`).
4. Check internal and external network connectivity.
5. Check public HTTPS endpoints from an external vantage point.
6. Verify core user flows (authentication, data loading, CRUD operations).

---

### PRODUCTION RULE #7 — DOCUMENT AFTER CHANGE

**AFTER EVERY SIGNIFICANT PRODUCTION CHANGE:**

Immediately update:
- `PRODUCTION_STATE.md` (Update verified live state, dates, container versions, hashes)
- `PRODUCTION_CHANGELOG.md` (Record timestamp, change details, rationale, files affected, verification proof, rollback steps)

---

### PRODUCTION RULE #8 — NO ARCHITECTURE REPLACEMENT WITHOUT PLAN

**DO NOT REPLACE CORE ARCHITECTURE COMPONENTS WITHOUT AN APPROVED PLAN.**

Do not replace, re-architect, or swap out:
- Traefik reverse proxy
- Docker Compose multi-stack architecture
- Supabase (GoTrue, PostgREST, Kong, Storage, Realtime)
- PostgreSQL relational database
- MinIO object storage
- Redis caching engine
- SRE monitoring stack (Prometheus, Grafana, Uptime Kuma)

*Architecture substitutions require an approved RFC, migration runbook, and explicit user sign-off.*

---

### PRODUCTION RULE #9 — COOLIFY INSTALLATION POLICY

**COOLIFY IS A SEPARATE INFRASTRUCTURE PROJECT.**

- **DO NOT install Coolify yet.**
- First establish and stabilize the production baseline documentation and safety system.
- When Coolify is introduced:
  - Document existing architecture and ownership.
  - Determine whether Coolify will coexist with Traefik or take over ingress ports (80/443).
  - Determine certificate ownership (Let's Encrypt / ACME).
  - Determine deployment ownership and CI/CD workflow.
  - Create and verify full database, storage, and configuration backups.
  - Test on a non-production/staging domain first.
  - Only then migrate production traffic with an approved rollback plan.

---

### PRODUCTION RULE #10 — WHEN DOCUMENTATION AND LIVE SERVER DIFFER

**IF A DISCREPANCY IS DISCOVERED BETWEEN DOCUMENTATION AND LIVE SERVER:**

**STOP IMMEDIATELY.** Do not guess. Do not assume either is automatically correct.

Report the discrepancy using this exact format:

```text
DOCUMENTED:
<What the documentation stated>

LIVE:
<What the live server inspection revealed>

DIFFERENCE:
<The exact delta and discrepancy analysis>
```

Investigate root cause, determine the authoritative state with the user, and update documentation accordingly.
