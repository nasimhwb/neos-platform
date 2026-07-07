import { Header } from "@/components/layout/Header";
import { StatusBadge } from "@/components/shared/StatusBadge";
import { MetricCard } from "@/components/shared/MetricCard";
import { mockRedisStats } from "@/lib/mock-data";
import { formatBytes, formatUptime, formatRelativeTime } from "@/lib/utils";
import { Zap, Key, Users, Clock, Database, Activity } from "lucide-react";

export default function RedisPage() {
  const stats = mockRedisStats;

  return (
    <div className="flex flex-col h-full">
      <Header title="Redis 8" subtitle={`v${stats.version} · ${stats.stats.opsPerSec} ops/sec`} />

      <div className="flex-1 overflow-y-auto p-6 space-y-6">
        {/* Status row */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <MetricCard title="Status" value={<StatusBadge status={stats.status} />} icon={Zap} />
          <MetricCard title="Memory Used" value={formatBytes(stats.memory.used)} subtitle={`of ${formatBytes(stats.memory.max)} max`} icon={Database} usagePercent={stats.memory.usagePercent} />
          <MetricCard title="Total Keys" value={stats.keys.total.toLocaleString()} subtitle={`${stats.keys.expiring} expiring`} icon={Key} />
          <MetricCard title="Connected Clients" value={stats.clients.connected} subtitle={`${stats.clients.blocked} blocked`} icon={Users} />
        </div>

        {/* Stats Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {/* Performance */}
          <div className="bg-card border border-border rounded-xl p-5">
            <h3 className="text-xs font-semibold text-muted-foreground uppercase tracking-wider mb-4 flex items-center gap-2">
              <Activity className="w-4 h-4" /> Performance
            </h3>
            <div className="space-y-3">
              {[
                { label: "Ops/second", value: stats.stats.opsPerSec.toLocaleString() },
                { label: "Total Commands", value: stats.stats.totalCommands.toLocaleString() },
                { label: "Cache Hit Rate", value: `${stats.stats.hitRate}%` },
                { label: "Network Input", value: formatBytes(stats.stats.networkInput) },
                { label: "Network Output", value: formatBytes(stats.stats.networkOutput) },
                { label: "Fragmentation Ratio", value: stats.memory.fragmentation.toFixed(2) },
              ].map(item => (
                <div key={item.label} className="flex items-center justify-between">
                  <span className="text-sm text-muted-foreground">{item.label}</span>
                  <span className="text-sm font-mono font-medium text-foreground">{item.value}</span>
                </div>
              ))}
            </div>
          </div>

          {/* Persistence */}
          <div className="bg-card border border-border rounded-xl p-5">
            <h3 className="text-xs font-semibold text-muted-foreground uppercase tracking-wider mb-4 flex items-center gap-2">
              <Database className="w-4 h-4" /> Persistence
            </h3>
            <div className="space-y-3">
              <div className="flex items-center justify-between">
                <span className="text-sm text-muted-foreground">AOF Enabled</span>
                <StatusBadge status={stats.persistence.aofEnabled ? "healthy" : "stopped"} />
              </div>
              <div className="flex items-center justify-between">
                <span className="text-sm text-muted-foreground">RDB Enabled</span>
                <StatusBadge status={stats.persistence.rdbEnabled ? "healthy" : "stopped"} />
              </div>
              <div className="flex items-center justify-between">
                <span className="text-sm text-muted-foreground">Last BG Save</span>
                <StatusBadge status={stats.persistence.lastBgSaveStatus === "ok" ? "healthy" : "unhealthy"} />
              </div>
              <div className="flex items-center justify-between">
                <span className="text-sm text-muted-foreground">Last Save</span>
                <span className="text-sm font-mono text-muted-foreground">{formatRelativeTime(stats.persistence.lastSave)}</span>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-sm text-muted-foreground">Uptime</span>
                <span className="text-sm font-mono text-muted-foreground">{formatUptime(stats.uptime)}</span>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-sm text-muted-foreground">Keys Evicted</span>
                <span className="text-sm font-mono text-foreground">{stats.keys.evicted}</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
