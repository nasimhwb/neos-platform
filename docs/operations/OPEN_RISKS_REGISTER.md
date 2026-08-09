# NEOS Platform — Open Risks Register

**Role:** DevSecOps Lead & Release Manager  
**Evaluation Date:** 2026-07-23  
**Scope:** Production System Post-Cutover Operational Risk Tracking  

---

## Executive Summary

While all critical blockers have been resolved and the platform is authorized for production cutover (**GO FOR PRODUCTION**), this risk register tracks minor operational considerations, their mitigation controls, impact, probability, and monitoring triggers.

---

## Risk Inventory Matrix

| Risk ID | Vulnerability / Risk Description | Severity | Probability | Existing Mitigation Control | Monitoring Trigger & Owner |
| :---: | :--- | :---: | :---: | :--- | :--- |
| **RISK-01** | PostgREST static connection pool saturation under 50+ concurrent user spikes | Low | Medium | Multi-tier load test verified 30 users at 326ms avg latency; PgBouncer pooler recommended for post-go-live | Prometheus `PostgresConnectionsHigh` alert (> 80 conns) (DBA Lead) |
| **RISK-02** | Let's Encrypt SSL certificate renewal failure due to HTTP challenge block | Low | Low | UFW allows port 80/443; Certbot auto-renew active | Prometheus `SSLCertificateExpiringSoon` (< 30 days) (DevSecOps Lead) |
| **RISK-03** | Local disk storage exhaustion if log rotation fails | Low | Low | Docker log driver set to `json-file` with `max-size: 50m`, `max-file: 3` across all services | Prometheus `HostDiskSpaceLow` alert (< 15% free on `/`) (SRE Lead) |
| **RISK-04** | Cloudflare DNS propagation delay on legacy ISP resolvers | Low | Low | DNS TTL lowered to 120 seconds (2 minutes) at T-7 days | Blackbox HTTP probe monitoring (Net Lead) |
| **RISK-05** | Daily backup mtime delay if backup cron hangs | Low | Low | Backup script outputs automated mtime; automated restore sandbox script verified | Prometheus `BackupJobMissing` alert (> 26 hours) (SRE Lead) |

---

## Risk Acceptability Verdict

> [!NOTE]
> All 5 identified open risks are classified as **LOW SEVERITY** with robust automated monitoring alerts in Prometheus and Alertmanager. None of these items block production deployment.
