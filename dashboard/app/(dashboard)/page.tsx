import { Header } from "@/components/layout/Header";
import { MetricCard } from "@/components/shared/MetricCard";
import { StatusBadge } from "@/components/shared/StatusBadge";
import { mockSystemMetrics, mockPlatformInfo, mockDockerStatus, mockAlerts } from "@/lib/mock-data";
import { formatBytes, formatUptime, formatRelativeTime } from "@/lib/utils";
import {
  Cpu, MemoryStick, HardDrive, Activity, Container, GitBranch,
  GitCommit, Clock, Server, AlertTriangle, CheckCircle2, Network,
} from "lucide-react";

export default function OverviewPage() {
  const metrics = mockSystemMetrics;
  const platform = mockPlatformInfo;
  const docker = mockDockerStatus;
  const firingAlerts = mockAlerts.filter(a => a.status === "firing");

  return (
    <div className="flex flex-col h-full">
      <Header title="Platform Overview" subtitle="Real-time system health and status" />

      <div className="flex-1 overflow-y-auto p-6 space-y-6">
        {/* Firing Alerts Banner */}
        {firingAlerts.length > 0 && (
          <div className="flex items-center gap-3 bg-amber-500/10 border border-amber-500/20 rounded-xl px-4 py-3">
            <AlertTriangle className="w-4 h-4 text-amber-400 flex-shrink-0" />
            <p className="text-sm text-amber-300">
              <span className="font-semibold">{firingAlerts.length} alert{firingAlerts.length > 1 ? "s" : ""} firing</span>
              {" — "}
              {firingAlerts.map(a => a.name).join(", ")}
            </p>
          </div>
        )}

        {/* System Resources */}
        <div>
          <h2 className="text-sm font-semibold text-muted-foreground uppercase tracking-wider mb-3">System Resources</h2>
          <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
            <MetricCard
              title="CPU Usage"
              value={`${metrics.cpu.usage}%`}
              subtitle={`${metrics.cpu.cores} cores · ${metrics.cpu.model.split(" ")[0]}`}
              icon={Cpu}
              usagePercent={metrics.cpu.usage}
            />
            <MetricCard
              title="Memory"
              value={formatBytes(metrics.memory.used)}
              subtitle={`of ${formatBytes(metrics.memory.total)} total`}
              icon={MemoryStick}
              usagePercent={metrics.memory.usagePercent}
            />
            <MetricCard
              title="Disk"
              value={formatBytes(metrics.disk.used)}
              subtitle={`of ${formatBytes(metrics.disk.total)} total`}
              icon={HardDrive}
              usagePercent={metrics.disk.usagePercent}
            />
            <MetricCard
              title="Load Average"
              value={metrics.loadAverage[0].toFixed(2)}
              subtitle={`5m: ${metrics.loadAverage[1].toFixed(2)} · 15m: ${metrics.loadAverage[2].toFixed(2)}`}
              icon={Activity}
            />
          </div>
        </div>

        {/* Network & Swap */}
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
          <MetricCard
            title="Network RX"
            value={`${formatBytes(metrics.network.rxRate)}/s`}
            subtitle={`Total: ${formatBytes(metrics.network.rxBytes)}`}
            icon={Network}
          />
          <MetricCard
            title="Network TX"
            value={`${formatBytes(metrics.network.txRate)}/s`}
            subtitle={`Total: ${formatBytes(metrics.network.txBytes)}`}
            icon={Network}
          />
          <MetricCard
            title="Swap"
            value={formatBytes(metrics.swap.used)}
            subtitle={`of ${formatBytes(metrics.swap.total)} total`}
            icon={HardDrive}
            usagePercent={metrics.swap.usagePercent}
          />
          <MetricCard
            title="System Uptime"
            value={formatUptime(metrics.uptime)}
            subtitle={metrics.os}
            icon={Clock}
          />
        </div>

        {/* Docker Status */}
        <div>
          <h2 className="text-sm font-semibold text-muted-foreground uppercase tracking-wider mb-3">Docker Engine</h2>
          <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
            <MetricCard title="Total Containers" value={docker.containers.total} icon={Container} />
            <div className="bg-card border border-border rounded-xl p-4">
              <p className="text-xs font-medium text-muted-foreground uppercase tracking-wider mb-3">Container States</p>
              <div className="space-y-2">
                <div className="flex items-center justify-between">
                  <span className="text-sm text-muted-foreground flex items-center gap-2">
                    <span className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse" />Running
                  </span>
                  <span className="text-sm font-semibold text-foreground">{docker.containers.running}</span>
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-sm text-muted-foreground flex items-center gap-2">
                    <span className="w-2 h-2 rounded-full bg-slate-400" />Stopped
                  </span>
                  <span className="text-sm font-semibold text-foreground">{docker.containers.stopped}</span>
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-sm text-muted-foreground flex items-center gap-2">
                    <span className="w-2 h-2 rounded-full bg-amber-400" />Paused
                  </span>
                  <span className="text-sm font-semibold text-foreground">{docker.containers.paused}</span>
                </div>
              </div>
            </div>
            <MetricCard title="Images" value={docker.images} subtitle={`${docker.volumes} volumes`} icon={Server} />
            <MetricCard title="Networks" value={docker.networks} subtitle={`Docker v${docker.version}`} icon={Network} />
          </div>
        </div>

        {/* Platform Info */}
        <div>
          <h2 className="text-sm font-semibold text-muted-foreground uppercase tracking-wider mb-3">Platform Status</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {/* Last Deployment */}
            <div className="bg-card border border-border rounded-xl p-4 space-y-3">
              <div className="flex items-center justify-between">
                <p className="text-xs font-medium text-muted-foreground uppercase tracking-wider">Last Deployment</p>
                <StatusBadge status="success" />
              </div>
              <div className="space-y-1.5">
                <div className="flex items-center gap-2">
                  <GitCommit className="w-3.5 h-3.5 text-muted-foreground" />
                  <code className="text-sm font-mono text-foreground">{platform.gitCommit}</code>
                </div>
                <div className="flex items-center gap-2">
                  <GitBranch className="w-3.5 h-3.5 text-muted-foreground" />
                  <span className="text-sm text-muted-foreground">{platform.gitBranch}</span>
                </div>
                <div className="flex items-center gap-2">
                  <Clock className="w-3.5 h-3.5 text-muted-foreground" />
                  <span className="text-sm text-muted-foreground">{formatRelativeTime(platform.lastDeployment)}</span>
                </div>
              </div>
            </div>

            {/* Host Info */}
            <div className="bg-card border border-border rounded-xl p-4 space-y-3">
              <p className="text-xs font-medium text-muted-foreground uppercase tracking-wider">Host Information</p>
              <div className="space-y-1.5 text-sm">
                <div className="flex justify-between">
                  <span className="text-muted-foreground">Hostname</span>
                  <span className="font-mono text-foreground">{metrics.hostname}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-muted-foreground">Kernel</span>
                  <span className="font-mono text-foreground text-xs">{metrics.kernel.split("-")[0]}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-muted-foreground">Environment</span>
                  <StatusBadge status={platform.environment === "production" ? "healthy" : "warning"} />
                </div>
                <div className="flex justify-between">
                  <span className="text-muted-foreground">Active Color</span>
                  <span className={`font-semibold text-sm ${platform.deploymentColor === "blue" ? "text-blue-400" : "text-emerald-400"}`}>
                    {platform.deploymentColor}
                  </span>
                </div>
              </div>
            </div>

            {/* Services Health */}
            <div className="bg-card border border-border rounded-xl p-4 space-y-3">
              <p className="text-xs font-medium text-muted-foreground uppercase tracking-wider">Services Health</p>
              <div className="space-y-2">
                {[
                  { name: "PostgreSQL", status: "healthy" },
                  { name: "Redis", status: "healthy" },
                  { name: "MinIO", status: "healthy" },
                  { name: "Traefik", status: "healthy" },
                  { name: "Prometheus", status: "healthy" },
                  { name: "Grafana", status: "healthy" },
                ].map(svc => (
                  <div key={svc.name} className="flex items-center justify-between">
                    <span className="text-sm text-muted-foreground">{svc.name}</span>
                    <div className="flex items-center gap-1.5">
                      <CheckCircle2 className="w-3.5 h-3.5 text-emerald-400" />
                      <span className="text-xs text-emerald-400">Online</span>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
