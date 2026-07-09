"use client";

import { Header } from "@/components/layout/Header";
import { MetricCard } from "@/components/shared/MetricCard";
import { StatusBadge } from "@/components/shared/StatusBadge";
import { useApiData } from "@/lib/hooks/useApiData";
import { mockSystemMetrics, mockPlatformInfo, mockDockerStatus } from "@/lib/mock-data";
import { formatBytes, formatUptime, formatRelativeTime } from "@/lib/utils";
import {
  Cpu, MemoryStick, HardDrive, Activity, Container, GitBranch,
  GitCommit, Clock, Server, AlertTriangle, CheckCircle2, Network,
  ShieldCheck,
} from "lucide-react";

export default function OverviewPage() {
  // Fetch live system metrics (host + platform info)
  const { data: sysData, loading: sysLoading } = useApiData("/api/system", {
    metrics: mockSystemMetrics,
    platform: mockPlatformInfo,
  });

  // Fetch live docker stats
  const { data: dockerData, loading: dockerLoading } = useApiData("/api/docker", {
    status: mockDockerStatus,
    containers: [],
    networks: [],
    volumes: [],
  });

  // Fetch live health checklist
  const { data: healthData, loading: healthLoading } = useApiData("/api/health", {
    overall: "healthy",
    services: [
      { name: "PostgreSQL", status: "healthy" },
      { name: "Redis", status: "healthy" },
      { name: "MinIO", status: "healthy" },
      { name: "Docker", status: "healthy" },
      { name: "Monitoring", status: "healthy" },
    ],
    system: { cpuUsage: 0, memoryUsage: 0, diskUsage: 0 },
  });

  // Fetch live backup health status
  const { data: backupHealth } = useApiData("/api/backups/health", {
    status: "healthy",
    lastBackupTime: null,
    durationSeconds: 0,
    sizeBytes: 0,
    offsiteStatus: "success",
    checksumStatus: "verified",
    error: null,
  });

  const metrics = sysData.metrics;
  const platform = sysData.platform;
  const docker = dockerData.status;
  const servicesList = healthData.services;

  const isDataLoading = sysLoading && dockerLoading && healthLoading;

  return (
    <div className="flex flex-col h-full">
      <Header 
        title="Platform Overview" 
        subtitle="Real-time system health and status" 
      />

      <div className="flex-1 overflow-y-auto p-6 space-y-6">
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
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
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
                {servicesList.map(svc => (
                  <div key={svc.name} className="flex items-center justify-between">
                    <span className="text-sm text-muted-foreground">{svc.name}</span>
                    <div className="flex items-center gap-1.5">
                      {svc.status === "healthy" ? (
                        <>
                          <CheckCircle2 className="w-3.5 h-3.5 text-emerald-400" />
                          <span className="text-xs text-emerald-400">Online</span>
                        </>
                      ) : svc.status === "degraded" ? (
                        <>
                          <AlertTriangle className="w-3.5 h-3.5 text-amber-400" />
                          <span className="text-xs text-amber-400">Degraded</span>
                        </>
                      ) : (
                        <>
                          <AlertTriangle className="w-3.5 h-3.5 text-red-400" />
                          <span className="text-xs text-red-400">Offline</span>
                        </>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* Backup & Recovery Status */}
            <div className="bg-card border border-border rounded-xl p-4 space-y-3">
              <div className="flex items-center justify-between">
                <p className="text-xs font-medium text-muted-foreground uppercase tracking-wider">Backup & Recovery</p>
                <StatusBadge status={backupHealth.status === "healthy" ? "healthy" : "failed"} />
              </div>
              <div className="space-y-1.5 text-sm">
                <div className="flex justify-between">
                  <span className="text-muted-foreground">Last Run</span>
                  <span className="text-foreground text-xs font-medium">
                    {backupHealth.lastBackupTime ? formatRelativeTime(backupHealth.lastBackupTime) : "Never"}
                  </span>
                </div>
                <div className="flex justify-between">
                  <span className="text-muted-foreground">Archive Size</span>
                  <span className="font-mono text-foreground text-xs">
                    {backupHealth.sizeBytes > 0 ? formatBytes(backupHealth.sizeBytes) : "0 B"}
                  </span>
                </div>
                <div className="flex justify-between">
                  <span className="text-muted-foreground">Offsite Sync</span>
                  <span className={`text-xs font-semibold capitalize ${backupHealth.offsiteStatus === "success" ? "text-emerald-400" : backupHealth.offsiteStatus === "skipped" ? "text-slate-400" : "text-amber-400"}`}>
                    {backupHealth.offsiteStatus}
                  </span>
                </div>
                <div className="flex justify-between">
                  <span className="text-muted-foreground">Checksum</span>
                  <span className={`text-xs font-semibold capitalize ${backupHealth.checksumStatus === "verified" || backupHealth.checksumStatus === "generated" ? "text-emerald-400" : "text-red-400"}`}>
                    {backupHealth.checksumStatus}
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
