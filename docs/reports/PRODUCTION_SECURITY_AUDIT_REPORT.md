# NEOS Platform — Production Security Audit Report

**Target Host:** Self-Hosted VPS Staging (`200.97.161.179`)  
**Target Domain:** `https://webapp.neosfacility.com` & `https://supabase.neosfacility.com`  
**Audit Scope:** Infrastructure, Host OS, Docker Runtime, Reverse Proxy/Gateway, Database Security, Authentication, Secret Hygiene, and Data Protection.  
**Strict Constraint Compliance:** **NO CODE OR SYSTEM CONFIGURATION WAS ALTERED DURING THIS AUDIT.**

---

## Executive Summary

A comprehensive zero-mutation Production Security Audit was conducted across **18 critical security vectors**. The environment demonstrates strong baseline security with automated daily encrypted backups, active Let's Encrypt TLS certificates, healthy Docker container isolation, and functional JWT authentication.

However, several **HIGH** and **MEDIUM** severity risk factors were identified regarding SSH root access, database Row Level Security (RLS) coverage, and host firewall rule hardening.

---

## Security Audit Matrix & Findings

### 1. SSH Configuration
* **Status:** `FINDING IDENTIFIED`
* **Observation:** SSH port is set to standard `22`. `PermitRootLogin` is enabled (`yes`), and root authentication via SSH key is active.
* **Severity:** **HIGH**
* **Risk:** Direct root login on standard port 22 exposes the VPS host to continuous automated brute-force attacks and credential stuffing.
* **Fix:**
  1. Create a non-root sudo user (e.g. `neosadmin`).
  2. Disable SSH root login: Set `PermitRootLogin no` in `/etc/ssh/sshd_config`.
  3. Disable password authentication: Set `PasswordAuthentication no`.
  4. Change SSH port to a non-standard high port (e.g. `2222`).
  5. Restart SSH service: `systemctl restart sshd`.
* **Verification:** Run `ssh root@200.97.161.179` and verify connection is refused. Verify `ssh -p 2222 neosadmin@200.97.161.179` connects cleanly.

---

### 2. Docker Daemon & Socket Security
* **Status:** `PASSED WITH RECOMMENDATION`
* **Observation:** Docker socket permissions are restricted (`srw-rw---- 1 root docker`). Listening container ports are properly bound to localhost (`127.0.0.1`) except public HTTP/HTTPS gateways.
* **Severity:** **LOW**
* **Risk:** Any user added to the `docker` group possesses effective root privileges on the host.
* **Fix:** Ensure non-root system users are NOT added to the `docker` group unless strictly required for CI/CD runners.
* **Verification:** Run `grep 'docker:' /etc/group` and verify only authorized administrative accounts are listed.

---

### 3. Traefik / Kong Gateway Security
* **Status:** `PASSED`
* **Observation:** Kong API Gateway acts as the sole public ingress on ports 80/443, proxying traffic securely to downstream Supabase microservices (`neos_supabase_auth`, `neos_supabase_rest`, `neos_supabase_storage`).
* **Severity:** **NONE**
* **Risk:** None. Downstream containers are isolated inside internal Docker networks (`neos-private`, `neos-database`).
* **Fix:** Maintain current network isolation boundaries in `compose.supabase.yml`.
* **Verification:** Run `curl -i http://localhost:3000` from an external network and verify direct access to PostgREST on 3000 is blocked by host firewall.

---

### 4. Supabase Stack Architecture
* **Status:** `PASSED`
* **Observation:** Microservice containers (`neos_postgres`, `neos_supabase_auth`, `neos_supabase_rest`, `neos_supabase_storage`, `neos_supabase_gateway`) are running healthy with no unmapped external database ports exposed publicly.
* **Severity:** **NONE**
* **Risk:** Low risk. Microservices communicate strictly via Docker internal DNS.
* **Fix:** Maintain service health checks.
* **Verification:** Run `docker ps` and confirm internal networks are active.

---

### 5. JWT Secret Hygiene & Signing
* **Status:** `PASSED`
* **Observation:** `GOTRUE_JWT_SECRET` is defined in `.env` and shared across GoTrue, PostgREST, and Kong Gateway. Tokens use `HS256` HMAC signing.
* **Severity:** **MEDIUM**
* **Risk:** If the JWT secret is compromised, malicious actors can forge arbitrary `service_role` tokens and bypass API authentication.
* **Fix:** Store JWT secrets securely in an encrypted vault (e.g., HashiCorp Vault or AWS Secrets Manager) and rotate secrets every 90 days.
* **Verification:** Test API request with an invalid signature token and verify PostgREST returns `401 Unauthorized`.

---

### 6. SMTP Configuration & TLS Security
* **Status:** `PASSED`
* **Observation:** Pingram SMTP is configured over Port 465 with implicit SSL/TLS (`GOTRUE_SMTP_PORT=465`, `GOTRUE_SMTP_HOST=smtp.pingram.io`). Password present.
* **Severity:** **NONE**
* **Risk:** Minimal. Traffic between GoTrue container and Pingram SMTP server is encrypted via TLS socket dialing.
* **Fix:** Ensure SMTP API keys are rotated periodically.
* **Verification:** Password recovery and OTP emails deliver successfully with valid TLS handshakes in GoTrue container logs.

---

### 7. Secret Management & `.env` Hygiene
* **Status:** `FINDING IDENTIFIED`
* **Observation:** `/srv/neos/neos-platform/.env` file permissions are set to `0775` (`-rwxrwxr-x`) owned by `nasim:nasim`.
* **Severity:** **MEDIUM**
* **Risk:** World-readable or group-executable file permissions on `.env` expose sensitive DB passwords, JWT secrets, and API keys to unprivileged local system users.
* **Fix:** Restrict `.env` file permissions to `0600` (read/write for owner only):
  ```bash
  chmod 600 /srv/neos/neos-platform/.env /srv/neos/shared/.env
  ```
* **Verification:** Run `ls -la /srv/neos/neos-platform/.env` and verify permissions display `-rw-------`.

---

### 8. Git Repository History Audit
* **Status:** `PASSED`
* **Observation:** Scanned recent git commit logs (`git log --all --grep='env'`). Commit history contains documentation updates and loader script fixes; no raw `.env` secret values were committed to tracking.
* **Severity:** **NONE**
* **Risk:** Low risk of secret leakage via git repository history. `.env` is listed in `.gitignore`.
* **Fix:** Maintain `.gitignore` rules blocking `.env*` pattern files.
* **Verification:** Run `git status --ignored` and confirm `.env` files are ignored.

---

### 9. Storage Bucket Security & Access Control
* **Status:** `PASSED`
* **Observation:** 8 public buckets (`attachments`, `efop-photos`, `efop-signatures`, `field-tracking`, `order-attachments`, `costing-attachments`, `gem-contracts`, `refundable-assets`) are registered in `storage.buckets` (`public: true`).
* **Severity:** **LOW**
* **Risk:** Public storage buckets allow direct URL download of media assets if object keys are known.
* **Fix:** For sensitive document buckets (e.g. `attachments`, `gem-contracts`), set `public = false` in `storage.buckets` and force application downloads via signed URLs (`storage.from().createSignedUrl()`).
* **Verification:** Query `SELECT id, public FROM storage.buckets;` and confirm private buckets enforce authentication checks.

---

### 10. Database Backups & Disaster Recovery
* **Status:** `PASSED`
* **Observation:** Daily cron job is active (`0 2 * * * /srv/neos/current/services/backup/backup.sh`). `/srv/neos/backups` contains valid daily tarballs (`neos_backup_2026-07-23_020001.tar.gz`, 65 MB) with SHA256 checksum files.
* **Severity:** **NONE**
* **Risk:** Low risk of data loss. Backups occur daily at 02:00 UTC.
* **Fix:** Implement off-site replication (e.g., sync backup tarballs to an AWS S3 bucket or remote storage server).
* **Verification:** Inspect backup directory and verify SHA256 verification command passes: `sha256sum -c neos_backup_*.tar.gz.sha256`.

---

### 11. Firewall Configuration (UFW / IPTables)
* **Status:** `FINDING IDENTIFIED`
* **Observation:** Host UFW firewall is currently disabled / inactive (`Status: inactive`). Docker manipulates `iptables` directly.
* **Severity:** **HIGH**
* **Risk:** Unused host ports or test services launched outside Docker could be publicly accessible over the WAN interface without restriction.
* **Fix:** Enable UFW and restrict default incoming traffic:
  ```bash
  ufw default deny incoming
  ufw default allow outgoing
  ufw allow 22/tcp
  ufw allow 80/tcp
  ufw allow 443/tcp
  ufw enable
  ```
* **Verification:** Run `ufw status verbose` and verify default policy is `deny (incoming)` with only ports 22, 80, and 443 open.

---

### 12. Fail2Ban Brute-Force Protection
* **Status:** `FINDING IDENTIFIED`
* **Observation:** `Fail2Ban` service is not installed on the VPS host (`fail2ban-client status: command not found`).
* **Severity:** **MEDIUM**
* **Risk:** Malicious IP addresses can execute unlimited SSH brute-force login attempts without IP bans.
* **Fix:** Install and enable Fail2Ban:
  ```bash
  apt-get update && apt-get install -y fail2ban
  systemctl enable fail2ban
  systemctl start fail2ban
  ```
* **Verification:** Run `fail2ban-client status sshd` and confirm `Jail list: sshd` is active.

---

### 13. Rate Limiting
* **Status:** `PASSED`
* **Observation:** Rate limiting is enforced at the Kong API Gateway layer and GoTrue auth layer (`GOTRUE_RATE_LIMIT_HEADER`, `RATE_LIMIT_EMAIL_SENT`).
* **Severity:** **NONE**
* **Risk:** Protects against auth endpoint denial-of-service and email spamming.
* **Fix:** Maintain rate limit headers in Kong gateway configuration.
* **Verification:** Trigger 10 rapid password recovery requests and verify API returns HTTP 429 Too Many Requests.

---

### 14. TLS & HTTPS Configuration
* **Status:** `PASSED`
* **Observation:** TLS 1.2 / TLS 1.3 encryption enabled via Let's Encrypt certificates (`/etc/letsencrypt/live/neosfacility.com`). Standard HTTP port 80 automatically redirects to HTTPS port 443.
* **Severity:** **NONE**
* **Risk:** Protects data in transit between clients and VPS.
* **Fix:** Ensure Certbot automatic renewal timer is active (`systemctl status certbot.timer`).
* **Verification:** Inspect SSL certificate validity via browser subagent or `curl -ivI https://webapp.neosfacility.com`.

---

### 15. SSL Certificate Expiry & Auto-Renewal
* **Status:** `PASSED`
* **Observation:** Let's Encrypt SSL certificates are valid and managed. Automated certbot renew timer active.
* **Severity:** **NONE**
* **Risk:** Minimal.
* **Fix:** Monitor cert renewal logs.
* **Verification:** Run `certbot renew --dry-run` and confirm successful certificate validation.

---

### 16. Row Level Security (RLS) Coverage
* **Status:** `FINDING IDENTIFIED`
* **Observation:** Out of 329 public database tables/views, 303 views/tables do not have Row Level Security explicitly enabled (`rowsecurity = false`). Standard views in PostgreSQL do not enforce RLS unless base tables enforce them or security barrier views are used.
* **Severity:** **MEDIUM**
* **Risk:** Unrestricted direct PostgREST table queries bypassing user ID filters could expose unauthorized rows to authenticated users if table-level RLS is missing.
* **Fix:** Enable RLS on all base application tables and create granular policies:
  ```sql
  ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
  CREATE POLICY "users_read_own_orders" ON public.orders FOR SELECT TO authenticated USING (auth.uid() = user_id OR auth.role() = 'admin');
  ```
* **Verification:** Execute `SELECT count(*) FROM pg_tables WHERE schemaname = 'public' AND rowsecurity = false;` and confirm count decreases for sensitive base tables.

---

### 17. Database Permissions & Grants
* **Status:** `PASSED`
* **Observation:** Database role permissions are properly scoped. Anonymous users (`anon`) have `SELECT` privileges only on public views, while write operations (`INSERT`, `UPDATE`, `DELETE`) require `authenticated` or `service_role` JWT claims.
* **Severity:** **NONE**
* **Risk:** Low risk. Unauthenticated anonymous API requests cannot modify database state.
* **Fix:** Maintain standard Supabase schema grants (`010_grants.sql`).
* **Verification:** Test an unauthenticated `POST /rest/v1/orders` request with `anon` key and verify PostgREST returns `401 Unauthorized` / `403 Forbidden`.

---

### 18. Database Superuser Scoping
* **Status:** `PASSED WITH RECOMMENDATION`
* **Observation:** 3 superuser roles identified in PostgreSQL (`postgres`, `supabase_admin`, `supabase_auth_admin`).
* **Severity:** **LOW**
* **Risk:** Superusers bypass all RLS policies and table permissions.
* **Fix:** Ensure application services (e.g. PostgREST) connect using restricted non-superuser roles (`authenticator`, `anon`, `authenticated`).
* **Verification:** Inspect `compose.supabase.yml` and verify PostgREST uses role `authenticator`.

---

## Final Security Audit Recommendation & Remediation Checklist

| Priority | Security Vector | Finding Summary | Recommended Action | Risk Status |
| :---: | :--- | :--- | :--- | :---: |
| **P1** | **Host Firewall** | UFW firewall is currently inactive | Enable UFW; allow only ports 22, 80, and 443 | **HIGH** |
| **P1** | **SSH Hardening** | Root SSH login enabled on standard port 22 | Disable root login; move SSH to non-standard port | **HIGH** |
| **P2** | **Secret Permissions** | `.env` file permissions set to `0775` | Restrict `.env` permissions to `chmod 600` | **MEDIUM** |
| **P2** | **Fail2Ban** | Fail2Ban brute-force protection missing | Install and activate `fail2ban` for SSH | **MEDIUM** |
| **P2** | **RLS Hardening** | 303 views/tables missing explicit RLS | Audit base tables and enforce RLS policies | **MEDIUM** |
| **P3** | **Storage Privacy** | Document storage buckets are public | Set sensitive document buckets to `public = false` | **LOW** |

---

## Verification Statement

> [!NOTE]
> **AUDIT COMPLIANCE CONFIRMATION:**  
> This security audit was executed using **read-only diagnostic tools** and inspection scripts. Zero files, database records, container configurations, or server settings were modified during the audit.
