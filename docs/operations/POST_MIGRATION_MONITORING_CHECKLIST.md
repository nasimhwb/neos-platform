# NEOS Platform — Post-Migration Monitoring Checklist

**Role:** Principal SRE & Monitoring Lead  
**Execution Window:** Immediately Following DNS Cutover (T+120 to T+180 Minutes)  
**Access Portal:** Grafana Dashboard (`https://monitor.neos-platform.local` or port 3000)  

---

## Post-Cutover Monitoring Tasks

### 1. Prometheus Scrape Target Inspection (T+125)
* [ ] Open Prometheus Targets Page (`http://localhost:9090/targets`).
* [ ] Verify all 9 scrape targets display **`UP (1/1)`**:
  * `prometheus`
  * `node-exporter`
  * `cadvisor`
  * `postgres-exporter`
  * `loki`
  * `alertmanager`
  * `blackbox-http`
  * `blackbox-smtp`

---

### 2. Grafana Executive Panel Audits (T+130)
* [ ] **Host CPU Utilization:** Verify CPU load is **< 25%** on 4 vCPU host.
* [ ] **Host Memory Consumption:** Verify memory usage is **< 3.5 GB / 8.0 GB** (RAM free > 4.0 GB).
* [ ] **Host Root Disk Usage:** Verify `/` partition free space is **> 70% free**.
* [ ] **PostgreSQL Connections:** Verify active connections count is **< 35 connections**.
* [ ] **GoTrue Auth Latency:** Verify authentication request p95 latency is **< 120 ms**.

---

### 3. Loki Container Log Stream Inspection (T+135)
* [ ] Open Grafana Explore tab → Select Data Source: **Loki**.
* [ ] Query `neos_supabase_gateway` log stream:
  ```logql
  {container_name="neos_supabase_gateway"} |= "status=5"
  ```
  *Expected Result:* **0 matching log lines** (Zero HTTP 5xx Gateway Errors).
* [ ] Query `neos_supabase_auth` log stream:
  ```logql
  {container_name="neos_supabase_auth"} |= "error"
  ```
  *Expected Result:* **0 critical auth errors**.

---

### 4. Executable CLI Health Check Script (T+140)
* [ ] Run SRE health check script on VPS host:
  ```bash
  ssh nasim@200.97.161.179 "/srv/neos/neos-platform/scripts/sre-health-check.sh"
  ```
  *Expected Result:* **`ALL SRE HEALTH CHECKS PASSED SUCCESSFULLY.`**
