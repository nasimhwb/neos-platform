# NEOS Platform — Production Migration & Cutover Runbook

**Role:** Release Manager, NEOS Platform  
**Document Status:** Approved for Execution  
**Target Execution Date:** Scheduled Maintenance Window (00:00 – 02:30 UTC)  
**Target VPS IP:** `200.97.161.179`  
**Production Ingress URLs:**  
* Web Application: `https://webapp.neosfacility.com`  
* Supabase API Engine: `https://supabase.neosfacility.com`  
* Frontend Host: Vercel Production (`neos-app-96.vercel.app`)  

---

## Executive Summary & Operating Guidelines

> [!IMPORTANT]
> **EXECUTABLE RUNBOOK INSTRUCTION:**  
> This document is designed to be executed by any engineer on call without prior project knowledge. Every command is explicit, copy-pasteable, and includes expected outputs and validation checks.

```
                                  ┌─────────────────────────────────────────┐
                                  │   PRODUCTION CUTOVER TIMELINE OVERVIEW  │
                                  └────────────────────┬────────────────────┘
                                                       │
        ┌───────────────────┬───────────────────┬──────┴────────────┬───────────────────┐
        ▼                   ▼                   ▼                   ▼                   ▼
     T-7 Days            T-3 Days            T-1 Day           Migration Day       Post-Migration
  [DNS TTL 120s]     [Schema Audit]     [Freeze Notice]    [00:00-02:30 UTC]    [SRE Monitoring]
```

---

## 1. Roles & Communication Matrix

| Role | Assigned Lead | Primary Responsibility | Contact |
| :--- | :--- | :--- | :--- |
| **Release Manager** | Lead Engineer | Cutover execution, step sign-offs, go/no-go decisions | Incident Channel |
| **Database Migration Engineer**| DB Lead | Data export, schema import, checksum verification | Incident Channel |
| **DevSecOps & Network Lead** | DevSecOps Lead | DNS cutover, SSL verification, firewall monitoring | Incident Channel |
| **QA / Smoke Test Lead** | QA Lead | Execution of Business Acceptance Test suite | Incident Channel |

---

## 2. Pre-Cutover Readiness Timeline

### T-7 Days — Initial Preparation & DNS TTL Lowering
* [ ] **Lower DNS TTLs:** Log in to Cloudflare DNS dashboard and change TTL for `webapp.neosfacility.com` and `supabase.neosfacility.com` from `Automatic (1 hour)` to **`2 minutes (120 seconds)`**.
* [ ] **Verify Backup Dry-Run:** Confirm daily backup script `/srv/neos/neos-platform/scripts/sre-health-check.sh` is executing cleanly on VPS staging.
* [ ] **Notify Stakeholders:** Broadcast T-7 Cutover Notice to NEOS executive staff and department leads.

### T-3 Days — Schema Alignment & Dry-Run Import
* [ ] **Verify Database Schema Parity:** Confirm VPS Postgres schema matches hosted Supabase production schema.
* [ ] **Dry-Run Storage Sync:** Perform a trial sync of MinIO storage object metadata.
* [ ] **Load Test Pass Confirmation:** Review `PERFORMANCE_LOAD_TEST_REPORT.md` (30 concurrent users, 46.46 RPS, 0% 5xx errors).

### T-1 Day — Freeze Announcement & Access Audit
* [ ] **Broadcast Maintenance Announcement:** Send final T-24h notification to staff (Maintenance Window: **00:00 - 02:30 UTC**).
* [ ] **SSH & Sudo Access Check:** Verify engineer SSH key access and sudo privileges:
  ```bash
  ssh nasim@200.97.161.179 "whoami; sudo id"
  ```
  *Expected Output:* `nasim` / `uid=0(root)`
* [ ] **Stage Migration Tools:** Ensure `/tmp/run_load_test.py` and `/tmp/sre-health-check.sh` are present on VPS.

---

## 3. Migration Day Minute-by-Minute Execution Runbook

### Phase 1: Maintenance Window Initiation & Write Freeze (00:00 - 00:15 UTC)

#### 00:00 UTC (T+00) — Declare Maintenance Window Active
1. Post Maintenance Window Start message to `#announcements` and staff channels.
2. Confirm all cutover team leads are present in the incident bridge.

#### 00:05 UTC (T+05) — Freeze Application Writes
1. Stop API Ingress containers on original host to block incoming user writes:
   ```bash
   ssh root@production-old "docker stop neos_supabase_gateway neos_supabase_rest"
   ```
2. Set PostgreSQL to Read-Only mode:
   ```bash
   ssh root@production-old "docker exec -i neos_postgres psql -U postgres -c 'ALTER SYSTEM SET default_transaction_read_only = ON; SELECT pg_reload_conf();'"
   ```
   *Expected Output:* `ALTER SYSTEM`, `pg_reload_conf: t`

---

### Phase 2: Final Backup & Data Export (00:15 - 00:45 UTC)

#### 00:15 UTC (T+15) — Take Final Production Snapshot
1. Trigger final pg_dumpall export on hosted production:
   ```bash
   ssh root@production-old "docker exec -i neos_postgres pg_dumpall -U postgres | gzip > /tmp/prod_final_dump_$(date +%F_%H%M).sql.gz"
   ```
2. Calculate SHA256 checksum of export:
   ```bash
   ssh root@production-old "sha256sum /tmp/prod_final_dump_*.sql.gz"
   ```
   *Record SHA256 Checksum:* `________________________________________________`

#### 00:30 UTC (T+30) — Export Storage Buckets & Configs
1. Archive MinIO storage bucket directory:
   ```bash
   ssh root@production-old "tar -czf /tmp/prod_minio_final.tar.gz -C /var/lib/docker/volumes/neos_minio_data/_data ."
   ```

---

### Phase 3: VPS Staging Import & Health Check (00:45 - 01:30 UTC)

#### 00:45 UTC (T+45) — Securely Transfer Dump to New VPS (`200.97.161.179`)
1. Transfer database dump and storage tarball to VPS:
   ```bash
   scp root@production-old:/tmp/prod_final_dump_*.sql.gz nasim@200.97.161.179:/tmp/
   scp root@production-old:/tmp/prod_minio_final.tar.gz nasim@200.97.161.179:/tmp/
   ```

#### 01:00 UTC (T+60) — Import Database to VPS PostgreSQL
1. Restore SQL dump into VPS `neos_postgres`:
   ```bash
   ssh nasim@200.97.161.179 "gunzip -c /tmp/prod_final_dump_*.sql.gz | sudo docker exec -i neos_postgres psql -U postgres -d postgres"
   ```
2. Disable Read-Only transaction mode on VPS:
   ```bash
   ssh nasim@200.97.161.179 "sudo docker exec -i neos_postgres psql -U postgres -c 'ALTER SYSTEM SET default_transaction_read_only = OFF; SELECT pg_reload_conf();'"
   ```

#### 01:15 UTC (T+75) — Unpack MinIO Storage Data
1. Unpack MinIO storage archive into Docker volume:
   ```bash
   ssh nasim@200.97.161.179 "sudo tar -xzf /tmp/prod_minio_final.tar.gz -C /var/lib/docker/volumes/neos_minio_data/_data/"
   ```

#### 01:25 UTC (T+85) — Run Unified SRE Health Check Script
1. Execute SRE health check script:
   ```bash
   ssh nasim@200.97.161.179 "/tmp/sre-health-check.sh"
   ```
   *Expected Output:* **`ALL SRE HEALTH CHECKS PASSED SUCCESSFULLY.`**

---

### Phase 4: Business Acceptance & Smoke Testing (01:30 - 02:00 UTC)

#### 01:30 UTC (T+90) — Execute Smoke Test Suite
QA Lead executes mandatory business workflows via staging domain:
1. [ ] **Auth Workflow:** Login (`fatma@neosfacility.com`) → Dashboard → Logout.
2. [ ] **Order Management:** View orders directory → Create quotation → Generate invoice PDF.
3. [ ] **HRMS Operations:** Employee attendance check-in update → Leave request view.
4. [ ] **GeM Operations:** GeM contract view & attachment download.
5. [ ] **GoTrue Email Test:** Password recovery trigger (`POST /recover`) → Confirm Pingram SMTP email receipt.

---

### Phase 5: DNS Cutover & Traffic Routing (02:00 - 02:15 UTC)

#### 02:00 UTC (T+120) — Update Cloudflare DNS Records
1. Open Cloudflare DNS Management Console.
2. Update **A Record** for `webapp.neosfacility.com` → Point to **`200.97.161.179`**.
3. Update **A Record** for `supabase.neosfacility.com` → Point to **`200.97.161.179`**.
4. Save DNS changes.

#### 02:10 UTC (T+130) — Verify Global DNS Propagation & SSL Ingress
1. Verify DNS resolution from local terminal:
   ```bash
   nslookup webapp.neosfacility.com
   nslookup supabase.neosfacility.com
   ```
   *Expected Output:* `200.97.161.179`
2. Test live HTTPS endpoints:
   ```bash
   curl -sk https://webapp.neosfacility.com/login | grep -i "NEOS"
   curl -sk https://supabase.neosfacility.com/auth/v1/health
   ```
   *Expected Output:* `HTTP 200 OK`

---

### Phase 6: Go-Live & Post-Migration Monitoring (02:15 - 02:30 UTC)

#### 02:15 UTC (T+135) — Monitor SRE Observability Dashboards
1. Open Grafana Dashboard (`https://monitor.neos-platform.local` or SSH tunnel to `localhost:3000`).
2. Inspect Node Exporter (CPU < 25%, RAM < 3.5 GB, Disk space > 80% free).
3. Inspect Postgres Exporter (Active connections < 35).
4. Inspect Loki container log stream for 0 HTTP 5xx errors.

#### 02:30 UTC (T+150) — Declare Migration Complete
1. Release Manager issues final sign-off.
2. Broadcast Go-Live Completion Announcement to staff.

---

## 4. Emergency Rollback Triggers & Procedure

### Rollback Trigger Criteria

> [!CAUTION]
> A Rollback MUST be initiated immediately if any of the following conditions occur:
> 1. Database restore failure or irrecoverable data corruption during import at T+60.
> 2. Critical QA Smoke Test failure (e.g., Auth failure or core order data missing) unresolved after 20 minutes.
> 3. Unresolved HTTP 500 error cascade on PostgREST or GoTrue API.
> 4. DNS cutover failure or routing loop persisting beyond T+140.

### Step-by-Step Emergency Rollback Runbook (Execution Time: < 8 Minutes)

#### Step 1: Revert Cloudflare DNS A Records
1. Log in to Cloudflare DNS Dashboard.
2. Immediately revert A Records for `webapp.neosfacility.com` and `supabase.neosfacility.com` back to original production IP address.
3. Save changes (TTL = 120s).

#### Step 2: Unfreeze Original Production Database
1. Connect to original production host:
   ```bash
   ssh root@production-old
   ```
2. Disable Read-Only mode:
   ```bash
   docker exec -i neos_postgres psql -U postgres -c "ALTER SYSTEM SET default_transaction_read_only = OFF; SELECT pg_reload_conf();"
   ```
3. Restart API Gateway containers:
   ```bash
   docker start neos_supabase_rest neos_supabase_gateway
   ```

#### Step 3: Broadcast Rollback Announcement
1. Notify stakeholders via `#announcements`:  
   *"The scheduled maintenance window has been extended due to a technical rollback. System access is restored on the primary environment. No data was lost."*

---

## 5. Stakeholder Communication Templates

### Template 1: T-24 Hours Maintenance Notice
```text
SUBJECT: Scheduled System Maintenance & Cutover — NEOS Platform

Dear NEOS Staff & Management,

Please be advised that the NEOS Platform will undergo scheduled production maintenance on [Date] between 00:00 UTC and 02:30 UTC.

During this window, the web application (webapp.neosfacility.com) will be temporarily offline for planned system upgrades. No user action is required.

Thank you for your cooperation.
NEOS Operations Team
```

### Template 2: Maintenance Window Initiation
```text
BROADCAST: Maintenance Window is NOW ACTIVE. System access is temporarily paused for planned migration. Estimated completion: 02:30 UTC.
```

### Template 3: Migration Success & Go-Live Announcement
```text
BROADCAST: System Migration Completed Successfully! The NEOS Platform is fully operational on our upgraded infrastructure. All services are healthy.
```

---

## Sign-Off & Approval

| Role | Name | Status | Timestamp |
| :--- | :--- | :---: | :---: |
| **Release Manager** | Lead Engineer | **APPROVED** | 2026-07-23 |
| **DevSecOps Lead** | Senior Engineer | **APPROVED** | 2026-07-23 |
| **QA Lead** | Principal QA | **APPROVED** | 2026-07-23 |
