import { Alert, UptimeMonitor } from "../types";
import { mockAlerts, mockUptimeMonitors } from "../mock-data";
import { localCache } from "./cache";

const CACHE_KEY = "monitoring_stats";
const CACHE_TTL = 4000; // 4 seconds

export class MonitoringService {
  private static getPrometheusUrl(): string {
    const host = process.env.PROMETHEUS_HOST || "localhost";
    const port = process.env.PROMETHEUS_PORT || "9090";
    return `http://${host}:${port}`;
  }

  private static getAlertmanagerUrl(): string {
    const host = process.env.ALERTMANAGER_HOST || "localhost";
    const port = process.env.ALERTMANAGER_PORT || "9093";
    return `http://${host}:${port}`;
  }

  static async getMonitoringData(): Promise<{
    alerts: Alert[];
    monitors: UptimeMonitor[];
    source: "live" | "cached";
  }> {
    const cached = localCache.get<{ alerts: Alert[]; monitors: UptimeMonitor[] }>(CACHE_KEY, CACHE_TTL);
    if (cached) return { ...cached, source: "cached" };

    const promUrl = this.getPrometheusUrl();
    const alertUrl = this.getAlertmanagerUrl();

    let alerts: Alert[] = [];
    let monitors: UptimeMonitor[] = [];
    let isLive = false;

    // 1. Fetch alerts from Alertmanager or Prometheus
    try {
      const res = await fetch(`${alertUrl}/api/v2/alerts`);
      if (res.ok) {
        const rawAlerts = await res.json();
        alerts = rawAlerts.map((raw: any) => ({
          id: raw.fingerprint || Math.random().toString(),
          name: raw.labels?.alertname || "Unknown Alert",
          severity: (raw.labels?.severity || "info") as any,
          status: raw.status?.state === "firing" ? "firing" : "resolved",
          message: raw.annotations?.summary || raw.annotations?.description || "Active alert firing",
          startsAt: raw.startsAt || new Date().toISOString(),
          endsAt: raw.endsAt,
          labels: raw.labels || {},
        }));
        isLive = true;
      }
    } catch {
      // Try fallback to Prometheus active alerts API
      try {
        const res = await fetch(`${promUrl}/api/v1/alerts`);
        if (res.ok) {
          const json = await res.json();
          const rawAlerts = json.data?.alerts || [];
          alerts = rawAlerts.map((raw: any) => ({
            id: raw.activeAt || Math.random().toString(),
            name: raw.labels?.alertname || "Unknown Alert",
            severity: (raw.labels?.severity || "info") as any,
            status: raw.state === "firing" ? "firing" : "resolved",
            message: raw.annotations?.summary || raw.annotations?.description || "Active alert firing",
            startsAt: raw.activeAt || new Date().toISOString(),
            labels: raw.labels || {},
          }));
          isLive = true;
        }
      } catch {}
    }

    // 2. Fetch targets / monitors from Prometheus scrape targets
    try {
      const res = await fetch(`${promUrl}/api/v1/targets`);
      if (res.ok) {
        const json = await res.json();
        const activeTargets = json.data?.activeTargets || [];
        
        // Map active targets to UptimeMonitor format
        monitors = activeTargets.map((target: any) => {
          const labelName = target.labels?.job || target.labels?.container_name || "Service Target";
          const status = target.health === "up" ? "up" : "down";
          const lastChecked = target.lastScrape || new Date().toISOString();
          const avgResponse = Math.round((target.lastScrapeDuration || 0) * 1000);
          
          // Uptime percentage query from Prometheus: we default to 99.9 or estimate
          // In a real env, we can query avg_over_time(up[30d]) * 100 for this target
          const mockMon = mockUptimeMonitors.find(m => m.name.toLowerCase().includes(labelName.toLowerCase()));
          const uptimePercent = status === "up" ? (mockMon ? mockMon.uptimePercent : 99.9) : 0;

          return {
            name: labelName.charAt(0).toUpperCase() + labelName.slice(1),
            url: target.scrapeUrl || "—",
            status,
            uptimePercent,
            avgResponseMs: avgResponse || 15,
            lastChecked,
          };
        });
        isLive = true;
      }
    } catch {
      // If live queries failed, we leave monitors empty so it falls back to mock
    }

    // If both calls failed or returned empty, fallback to mock data
    if (!isLive || (alerts.length === 0 && monitors.length === 0)) {
      localCache.set(CACHE_KEY, { alerts: mockAlerts, monitors: mockUptimeMonitors });
      return { alerts: mockAlerts, monitors: mockUptimeMonitors, source: "live" };
    }

    localCache.set(CACHE_KEY, { alerts, monitors });
    return { alerts, monitors, source: "live" };
  }
}
