# NEOS Platform — Production Rollback Plan

**Date:** 2026-08-02  
**Target Execution Time:** `< 2 Minutes`  
**Trigger Condition:** Unresolvable HTTP 5xx errors, auth failures, or data corruption detected on live production URL post-cutover.  

---

## 1. Rollback Procedure

In the event of a critical failure during cutover:

### Step 1 — Revert Cloudflare DNS (Time: 30 Seconds)
1. Log into Cloudflare Dashboard -> `neosfacility.com` -> DNS Records.
2. Select CNAME record `webapp.neosfacility.com`.
3. Revert Target to `cname.vercel-dns.com`.
4. Proxy status: `Proxied`.

### Step 2 — Re-Enable Supabase Cloud Gateway Traffic (Time: 30 Seconds)
1. Ensure Vercel environment variables point to `https://epcbqpkosqucugfbmveo.supabase.co`.
2. Confirm Vercel production deployment status is `Active`.

### Step 3 — Post-Rollback Validation (Time: 60 Seconds)
1. Open `https://webapp.neosfacility.com/login`.
2. Verify browser login succeeds against Supabase Cloud auth.
3. Confirm core workflows (Tasks, Orders) are fully functional.

---

## 2. Post-Mortem & Incident Isolation

* Do NOT modify production data after rollback.
* Freeze VPS container logs for diagnostic analysis (`docker logs neos_app > /tmp/rollback_incident.log`).
* Log incident cause in `docs/operations/KNOWN_ISSUES.md`.
