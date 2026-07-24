# NEOS Platform — Day 1 Operations Checklist

**Role:** Operations Lead & Release Manager  
**Scope:** First 24 Hours Post-Cutover  
**Target Date:** Day 1 Post-Go-Live  

---

## 1. Hourly Operational Checkpoints

| Time / Shift | Focus Area | Required Verification Action | Assigned Lead |
| :---: | :--- | :--- | :--- |
| **08:00 UTC (Staff Arrival)** | User Authentication | Monitor initial user login surge; verify zero password reset errors. | Support Lead |
| **10:00 UTC** | Order Operations | Verify order creation, PDF invoice generation, and GeM contract attachments. | Sales QA Lead |
| **12:00 UTC** | HR & Attendance | Verify employee check-in entries and payroll summary report loading. | HR QA Lead |
| **14:00 UTC** | Storage & Uploads | Inspect MinIO storage throughput and verify signed URL document access. | DevSecOps Lead |
| **18:00 UTC** | System Metrics | Review Prometheus CPU/RAM metrics and Loki log streams in Grafana. | SRE Lead |
| **02:00 UTC (+1 Day)** | Backup Execution | Verify automated daily backup tarball is generated in `/srv/neos/backups/`. | SRE Lead |

---

## 2. Escalation Procedure & Incident Triage

* **Severity 1 (Critical Outage):** Core web app or database unavailable.
  * *Action:* Release Manager summons Incident Command Bridge; evaluate Emergency Rollback or Container Restart (< 5m RTO).
* **Severity 2 (Degraded Feature):** Email delivery delay or storage upload slow.
  * *Action:* DevSecOps Lead inspects GoTrue logs & Pingram SMTP TLS connection.
* **Severity 3 (Minor UI / Query Glitch):** Non-blocking dashboard rendering issue.
  * *Action:* Log ticket in operational backlog for Week 1 patch release.
