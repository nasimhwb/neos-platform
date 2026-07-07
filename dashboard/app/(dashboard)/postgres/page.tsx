import { Header } from "@/components/layout/Header";
import { StatusBadge } from "@/components/shared/StatusBadge";
import { MetricCard } from "@/components/shared/MetricCard";
import { mockPostgresStats } from "@/lib/mock-data";
import { formatBytes, formatUptime } from "@/lib/utils";
import { Database, Users, Activity, Clock } from "lucide-react";

export default function PostgresPage() {
  const stats = mockPostgresStats;
  const totalSize = stats.databases.reduce((sum, db) => sum + db.sizeBytes, 0);

  return (
    <div className="flex flex-col h-full">
      <Header title="PostgreSQL 16" subtitle={`${stats.version.split(" ")[0]} ${stats.version.split(" ")[1]}`} />

      <div className="flex-1 overflow-y-auto p-6 space-y-6">
        {/* Status Cards */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <MetricCard title="Status" value={<StatusBadge status={stats.status} />} icon={Database} />
          <MetricCard title="Active Connections" value={stats.connections.active} subtitle={`${stats.connections.total}/${stats.connections.max} total`} icon={Activity} usagePercent={(stats.connections.total / stats.connections.max) * 100} />
          <MetricCard title="Total Storage" value={formatBytes(totalSize)} subtitle={`${stats.databases.length} databases`} icon={Database} />
          <MetricCard title="Uptime" value={formatUptime(stats.uptime)} icon={Clock} />
        </div>

        {/* Databases */}
        <div>
          <h2 className="text-sm font-semibold text-muted-foreground uppercase tracking-wider mb-3">Databases</h2>
          <div className="bg-card border border-border rounded-xl overflow-hidden">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-border bg-muted/30">
                  <th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground">Database</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground">Owner</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground">Size</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground hidden md:table-cell">Tables</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground hidden md:table-cell">Connections</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {stats.databases.map(db => (
                  <tr key={db.name} className="hover:bg-muted/20 transition-colors">
                    <td className="px-4 py-3 font-mono text-sm text-foreground font-medium">{db.name}</td>
                    <td className="px-4 py-3 font-mono text-xs text-muted-foreground">{db.owner}</td>
                    <td className="px-4 py-3 text-xs text-muted-foreground">{formatBytes(db.sizeBytes)}</td>
                    <td className="px-4 py-3 text-xs text-muted-foreground hidden md:table-cell">{db.tables}</td>
                    <td className="px-4 py-3 text-xs text-muted-foreground hidden md:table-cell">{db.connections}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>

        {/* Users & Roles */}
        <div>
          <h2 className="text-sm font-semibold text-muted-foreground uppercase tracking-wider mb-3 flex items-center gap-2">
            <Users className="w-4 h-4" /> Roles & Users
          </h2>
          <div className="bg-card border border-border rounded-xl overflow-hidden">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-border bg-muted/30">
                  <th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground">Role</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground">Superuser</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground">Can Login</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground hidden md:table-cell">Create DB</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {stats.users.map(u => (
                  <tr key={u.name} className="hover:bg-muted/20 transition-colors">
                    <td className="px-4 py-3 font-mono text-xs text-foreground">{u.name}</td>
                    <td className="px-4 py-3">
                      {u.superuser
                        ? <span className="text-amber-400 text-xs font-medium">Yes</span>
                        : <span className="text-muted-foreground text-xs">No</span>}
                    </td>
                    <td className="px-4 py-3">
                      {u.canLogin
                        ? <StatusBadge status="healthy" />
                        : <StatusBadge status="stopped" />}
                    </td>
                    <td className="px-4 py-3 text-xs text-muted-foreground hidden md:table-cell">
                      {u.canCreateDb ? "Yes" : "No"}
                    </td>
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
