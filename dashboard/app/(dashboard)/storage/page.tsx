import { Header } from "@/components/layout/Header";
import { StatusBadge } from "@/components/shared/StatusBadge";
import { MetricCard } from "@/components/shared/MetricCard";
import { mockMinioStats } from "@/lib/mock-data";
import { formatBytes, formatRelativeTime } from "@/lib/utils";
import { HardDrive, Package, Users, ShieldCheck } from "lucide-react";

export default function StoragePage() {
  const stats = mockMinioStats;

  return (
    <div className="flex flex-col h-full">
      <Header title="Object Storage" subtitle={`MinIO · ${stats.version}`} />

      <div className="flex-1 overflow-y-auto p-6 space-y-6">
        {/* Summary */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <MetricCard title="Status" value={<StatusBadge status={stats.status} />} icon={HardDrive} />
          <MetricCard title="Total Storage" value={formatBytes(stats.totalSizeBytes)} subtitle={`${stats.totalBuckets} buckets`} icon={HardDrive} />
          <MetricCard title="Total Objects" value={stats.totalObjects.toLocaleString()} icon={Package} />
          <MetricCard title="Access Users" value={stats.users.length} icon={Users} />
        </div>

        {/* Buckets */}
        <div>
          <h2 className="text-sm font-semibold text-muted-foreground uppercase tracking-wider mb-3">Buckets</h2>
          <div className="bg-card border border-border rounded-xl overflow-hidden">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-border bg-muted/30">
                  <th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground">Bucket</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground">Size</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground">Objects</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground hidden md:table-cell">Policy</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground hidden md:table-cell">Created</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {stats.buckets.map(bucket => (
                  <tr key={bucket.name} className="hover:bg-muted/20 transition-colors">
                    <td className="px-4 py-3 font-mono text-sm text-foreground font-medium">{bucket.name}</td>
                    <td className="px-4 py-3 text-xs text-muted-foreground">{formatBytes(bucket.sizeBytes)}</td>
                    <td className="px-4 py-3 text-xs text-muted-foreground">{bucket.objects.toLocaleString()}</td>
                    <td className="px-4 py-3 hidden md:table-cell">
                      <span className="flex items-center gap-1.5 text-xs text-muted-foreground">
                        <ShieldCheck className="w-3 h-3" /> {bucket.policy}
                      </span>
                    </td>
                    <td className="px-4 py-3 text-xs text-muted-foreground hidden md:table-cell">
                      {formatRelativeTime(bucket.created)}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>

        {/* Access Users */}
        <div>
          <h2 className="text-sm font-semibold text-muted-foreground uppercase tracking-wider mb-3 flex items-center gap-2">
            <Users className="w-4 h-4" /> Access Users
          </h2>
          <div className="bg-card border border-border rounded-xl overflow-hidden">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-border bg-muted/30">
                  <th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground">Access Key</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground">Status</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground">Policies</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground hidden md:table-cell">Created</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {stats.users.map(u => (
                  <tr key={u.accessKey} className="hover:bg-muted/20 transition-colors">
                    <td className="px-4 py-3 font-mono text-xs text-foreground">{u.accessKey}</td>
                    <td className="px-4 py-3"><StatusBadge status={u.status === "enabled" ? "healthy" : "stopped"} /></td>
                    <td className="px-4 py-3 text-xs text-muted-foreground">{u.policies.join(", ")}</td>
                    <td className="px-4 py-3 text-xs text-muted-foreground hidden md:table-cell">{formatRelativeTime(u.created)}</td>
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
