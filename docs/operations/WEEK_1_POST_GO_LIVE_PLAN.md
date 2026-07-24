# NEOS Platform — Week 1 Post-Go-Live Plan

**Role:** Chief Architect & SRE Lead  
**Scope:** Days 1 through 7 Post-Cutover Operations  

---

## 1. Daily Focus & Milestones Matrix

| Day | Focus Milestone | Action Items | Responsible Lead |
| :---: | :--- | :--- | :--- |
| **Day 1** | **Go-Live Stabilization** | Executive monitoring, user support queue triage, first daily backup verification. | Operations Lead |
| **Day 2** | **Backup & DR Audit** | Perform automated sandbox restore test on Day 1 backup tarball to verify RPO/RTO. | Principal SRE |
| **Day 3** | **Performance Optimization** | Evaluate PgBouncer pooler deployment and FK index tuning (`idx_orders_created_by`). | Principal DBA |
| **Day 4** | **Security & Firewall Audit**| Review Fail2Ban banned IP logs and verify UFW rules under full production load. | DevSecOps Lead |
| **Day 5** | **Storage & Log Pruning** | Audit MinIO storage bucket growth and verify Promtail/Loki log retention policies. | DevSecOps Lead |
| **Day 6** | **DNS TTL Normalization** | Increase Cloudflare DNS TTL from 120 seconds back to `Automatic (1 hour)`. | Network Lead |
| **Day 7** | **Post-Mortem & Decommission**| Finalize Post-Go-Live review; safely decommission legacy hosted Supabase instance. | Chief Architect |

---

## 2. Long-Term Reliability Controls

* **Weekly Backup Verification:** Automated cron running `/tmp/test_dr_restore.py` every Sunday at 03:00 UTC.
* **Monthly Security Patching:** Kernel and container image security updates on the first Tuesday of every month during off-peak hours.
