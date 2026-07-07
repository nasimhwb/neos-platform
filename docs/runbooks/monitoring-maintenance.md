# Production Monitoring & Alerting Operations Runbook

This document describes the operational maintenance, troubleshooting steps, and configurations for the NEOS Platform Prometheus, Grafana, Loki, Alertmanager, cAdvisor, and Blackbox monitoring stack.

---

## 1. Monitoring Stack Architecture

The monitoring platform is comprised of the following modular layers:

* **Prometheus**: Scrapes and stores time-series performance metrics.
* **Grafana**: Visualizes metrics through pre-loaded dashboards.
* **Loki & Promtail**: Collects, indexes, and stores log streams from Docker containers.
* **Alertmanager**: Deduplicates, groups, and routes active alerts (via email/webhooks).
* **Node Exporter**: Collects Host VPS resource metrics (CPU, memory, disk).
* **cAdvisor**: Exposes resource usage (CPU, memory, IO) per container.
* **Blackbox Exporter**: Probes HTTP/S endpoints and evaluates SSL certificate expiration thresholds.

---

## 2. Health Diagnostic Endpoints

To check the operational health of the telemetry services directly from the host VPS:

| Component | Port | Health CLI Check Command | Expected Output |
| :--- | :--- | :--- | :--- |
| **Prometheus** | `9090` | `curl -f http://localhost:9090/-/healthy` | `OK` |
| **Grafana** | `3000` | `curl -f http://localhost:3000/api/health` | `{"database": "ok"}` |
| **Alertmanager** | `9093` | `curl -f http://localhost:9093/-/healthy` | `OK` |
| **Loki** | `3100` | `curl -f http://localhost:3100/ready` | `ready` |
| **Blackbox Exporter** | `9115` | `curl -f http://localhost:9115/-/healthy` | `OK` (or HTML response) |

---

## 3. Alerts & Incident Management

Prometheus alert thresholds are configured in `configs/prometheus/alert.rules.yml`.

### How to Add or Modify Alert Rules
1. Edit [configs/prometheus/alert.rules.yml](file:///d:/Webapp/KVM2/neos-platform/configs/prometheus/alert.rules.yml).
2. Define a new alert rule block:
   ```yaml
   - alert: CustomAlertName
     expr: prometheus_metric_query > threshold_value
     for: 5m
     labels:
       severity: warning
     annotations:
       summary: "Short description of the alert"
       description: "Detailed description of the alert state"
   ```
3. Validate rules syntax (placeholder verification check):
   ```bash
   # If promtool is installed locally
   promtool check rules configs/prometheus/alert.rules.yml
   ```
4. Reload Prometheus configuration:
   ```bash
   curl -X POST http://localhost:9090/-/reload
   ```

---

## 4. SSL Expiration & Blackbox Monitoring

We use the Blackbox Exporter (`blackbox-exporter`) to ensure domains do not expire.

### Adding a New Domain to Probe
To start monitoring SSL certificate expiration for a new application (e.g. `payroll.neos-platform.local`):
1. Open [configs/prometheus/prometheus.yml](file:///d:/Webapp/KVM2/neos-platform/configs/prometheus/prometheus.yml).
2. Locate the `blackbox` scrape job.
3. Append the new domain under the `targets` array:
   ```yaml
         - targets:
             - https://payroll.neos-platform.local
   ```
4. Reload Prometheus configuration to start scraping metrics:
   ```bash
   curl -X POST http://localhost:9090/-/reload
   ```
5. You can verify the SSL expiry metric in Prometheus:
   `probe_ssl_earliest_cert_expiry` (exposes Unix timestamp of expiration).

---

## 5. Grafana Dashboard Provisioning

Grafana is configured to load dashboards dynamically from `/etc/grafana/provisioning/dashboards/`.
* Any JSON template dropped into [monitoring/provisioning/dashboards/](file:///d:/Webapp/KVM2/neos-platform/monitoring/provisioning/dashboards/) will be automatically picked up and updated in the Grafana UI within 10 seconds.
* Available Platform Dashboards:
  - `node-dashboard.json`: Host VPS metrics.
  - `docker-dashboard.json`: Container cAdvisor metrics.
  - `traefik-dashboard.json`: Ingress network metrics.
  - `postgresql-dashboard.json`: PostgreSQL database metrics.
  - `redis-dashboard.json`: Redis caching metrics.
  - `minio-dashboard.json`: MinIO object storage metrics.
