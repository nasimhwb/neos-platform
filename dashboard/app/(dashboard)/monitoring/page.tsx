import { Header } from "@/components/layout/Header";
import { StatusBadge } from "@/components/shared/StatusBadge";
import { mockAlerts, mockUptimeMonitors } from "@/lib/mock-data";
import { formatRelativeTime } from "@/lib/utils";
import { AlertTriangle, CheckCircle2, ExternalLink, Activity } from "lucide-react";

const severityColors: Record<string, string> = {
  critical: "text-red-400 bg-red-400/10 border-red-400/20",
  warning: "text-amber-400 bg-amber-400/10 border-amber-400/20",
  info: "text-blue-400 bg-blue-400/10 border-blue-400/20",
};

export default function MonitoringPage() {
  const alerts = mockAlerts;
  const monitors = mockUptimeMonitors;
  const firingAlerts = alerts.filter(a => a.status === "firing");

  return (
    <div className="flex flex-col h-full">
      <Header title="Monitoring" subtitle="Prometheus · Grafana · Loki · Alertmanager · Uptime Kuma" />

      <div className="flex-1 overflow-y-auto p-6 space-y-6">
        {/* External Links */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
          {[
            { name: "Grafana", url: "https://monitor.neos-platform.local", desc: "Dashboards" },
            { name: "Prometheus", url: "https://monitor.neos-platform.local:9090", desc: "Metrics" },
            { name: "Alertmanager", url: "https://monitor.neos-platform.local:9093", desc: "Alerts" },
            { name: "Uptime Kuma", url: "https://status.neos-platform.local", desc: "Status Page" },
          ].map(link => (
            <a key={link.name} href={link.url} target="_blank" rel="noopener noreferrer"
              className="bg-card border border-border rounded-xl p-4 hover:border-primary/40 hover:bg-muted/20 transition-all group flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-foreground">{link.name}</p>
                <p className="text-xs text-muted-foreground">{link.desc}</p>
              </div>
              <ExternalLink className="w-4 h-4 text-muted-foreground group-hover:text-foreground transition-colors" />
            </a>
          ))}
        </div>

        {/* Active Alerts */}
        <div>
          <h2 className="text-sm font-semibold text-muted-foreground uppercase tracking-wider mb-3 flex items-center gap-2">
            <AlertTriangle className="w-4 h-4" />
            Active Alerts
            {firingAlerts.length > 0 && (
              <span className="ml-1 px-1.5 py-0.5 text-xs bg-amber-500/20 text-amber-400 rounded-full">{firingAlerts.length}</span>
            )}
          </h2>
          <div className="space-y-2">
            {alerts.length === 0
              ? <div className="bg-card border border-border rounded-xl p-6 text-center text-muted-foreground text-sm">No alerts</div>
              : alerts.map(alert => (
                <div key={alert.id} className={`border rounded-xl px-4 py-3 flex items-start gap-3 ${severityColors[alert.severity]}`}>
                  {alert.status === "firing"
                    ? <AlertTriangle className="w-4 h-4 flex-shrink-0 mt-0.5" />
                    : <CheckCircle2 className="w-4 h-4 flex-shrink-0 mt-0.5" />}
                  <div className="flex-1">
                    <div className="flex items-center gap-2 mb-0.5">
                      <span className="text-sm font-semibold">{alert.name}</span>
                      <StatusBadge status={alert.status === "firing" ? "unhealthy" : "healthy"} />
                    </div>
                    <p className="text-xs opacity-80">{alert.message}</p>
                    <p className="text-xs opacity-60 mt-1">Started {formatRelativeTime(alert.startsAt)}</p>
                  </div>
                </div>
              ))}
          </div>
        </div>

        {/* Uptime Monitors */}
        <div>
          <h2 className="text-sm font-semibold text-muted-foreground uppercase tracking-wider mb-3 flex items-center gap-2">
            <Activity className="w-4 h-4" /> Uptime Monitors
          </h2>
          <div className="bg-card border border-border rounded-xl overflow-hidden">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-border bg-muted/30">
                  <th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground">Monitor</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground">Status</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground">Uptime</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground hidden md:table-cell">Avg Response</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground hidden md:table-cell">Last Checked</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {monitors.map(m => (
                  <tr key={m.name} className="hover:bg-muted/20 transition-colors">
                    <td className="px-4 py-3 font-medium text-foreground text-sm">{m.name}</td>
                    <td className="px-4 py-3"><StatusBadge status={m.status === "up" ? "healthy" : "unhealthy"} /></td>
                    <td className="px-4 py-3 text-xs font-mono">
                      <span className={m.uptimePercent >= 99.9 ? "text-emerald-400" : m.uptimePercent >= 99 ? "text-amber-400" : "text-red-400"}>
                        {m.uptimePercent.toFixed(2)}%
                      </span>
                    </td>
                    <td className="px-4 py-3 text-xs text-muted-foreground hidden md:table-cell">{m.avgResponseMs}ms</td>
                    <td className="px-4 py-3 text-xs text-muted-foreground hidden md:table-cell">{formatRelativeTime(m.lastChecked)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  );
}
