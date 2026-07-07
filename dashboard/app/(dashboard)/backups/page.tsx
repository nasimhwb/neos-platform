"use client";

import { Header } from "@/components/layout/Header";
import { StatusBadge } from "@/components/shared/StatusBadge";
import { MetricCard } from "@/components/shared/MetricCard";
import { useApiData } from "@/lib/hooks/useApiData";
import { mockBackups } from "@/lib/mock-data";
import { formatBytes, formatDuration, formatRelativeTime } from "@/lib/utils";
import { Archive, Clock, CheckCircle2, XCircle, ShieldCheck } from "lucide-react";

export default function BackupsPage() {
  const { data: backups } = useApiData("/api/backups", mockBackups);
  
  const lastBackup = backups[0] || { timestamp: new Date().toISOString(), status: "success", sizeBytes: 0, expiresAt: new Date().toISOString() };
  const successCount = backups.filter(b => b.status === "success").length;
  const totalSize = backups.filter(b => b.status === "success").reduce((sum, b) => sum + b.sizeBytes, 0);

  // Calculate next backup countdown
  const nextBackupTime = new Date();
  nextBackupTime.setUTCHours(2, 0, 0, 0); // 02:00 UTC
  if (nextBackupTime.getTime() <= Date.now()) {
    nextBackupTime.setUTCDate(nextBackupTime.getUTCDate() + 1);
  }
  const hoursRemaining = Math.max(1, Math.round((nextBackupTime.getTime() - Date.now()) / (1000 * 60 * 60)));

  return (
    <div className="flex flex-col h-full">
      <Header title="Backups" subtitle="GPG-encrypted daily backups with 14-day retention" />

      <div className="flex-1 overflow-y-auto p-6 space-y-6">
        {/* Summary Cards */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <MetricCard title="Last Backup" value={formatRelativeTime(lastBackup.timestamp)} subtitle={lastBackup.status} icon={Archive} />
          <MetricCard title="Success Rate" value={backups.length > 0 ? `${Math.round((successCount / backups.length) * 100)}%` : "100%"} subtitle={`${successCount}/${backups.length} backups`} icon={CheckCircle2} />
          <MetricCard title="Total Stored" value={formatBytes(totalSize)} subtitle={`${backups.length} backup files`} icon={Archive} />
          <MetricCard title="Retention" value={`${lastBackup.retentionDays || 14} days`} subtitle="Auto-purge enabled" icon={Clock} />
        </div>

        {/* Next backup countdown */}
        <div className="bg-card border border-border rounded-xl p-4 flex items-center gap-4">
          <div className="w-10 h-10 rounded-full bg-primary/10 flex items-center justify-center flex-shrink-0">
            <Clock className="w-5 h-5 text-primary" />
          </div>
          <div>
            <p className="text-sm font-medium text-foreground">Next Scheduled Backup</p>
            <p className="text-xs text-muted-foreground">Daily at 02:00 UTC — approximately in {hoursRemaining} hour{hoursRemaining > 1 ? "s" : ""}</p>
          </div>
          <div className="ml-auto">
            <StatusBadge status="healthy" />
          </div>
        </div>

        {/* Backup History */}
        <div>
          <h2 className="text-sm font-semibold text-muted-foreground uppercase tracking-wider mb-3">Backup History</h2>
          <div className="bg-card border border-border rounded-xl overflow-hidden">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-border bg-muted/30">
                  <th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground">Timestamp</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground">Status</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground">Size</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground hidden md:table-cell">Duration</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground hidden md:table-cell">Verified</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground hidden lg:table-cell">Encrypted</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground">Expires</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {backups.map(backup => (
                  <tr key={backup.id} className="hover:bg-muted/20 transition-colors">
                    <td className="px-4 py-3 text-xs text-foreground">
                      {new Date(backup.timestamp).toLocaleString()}
                    </td>
                    <td className="px-4 py-3"><StatusBadge status={backup.status} /></td>
                    <td className="px-4 py-3 text-xs text-muted-foreground">{backup.sizeBytes > 0 ? formatBytes(backup.sizeBytes) : "—"}</td>
                    <td className="px-4 py-3 text-xs text-muted-foreground hidden md:table-cell">{formatDuration(backup.duration)}</td>
                    <td className="px-4 py-3 hidden md:table-cell">
                      {backup.verified
                        ? <CheckCircle2 className="w-4 h-4 text-emerald-400" />
                        : <XCircle className="w-4 h-4 text-slate-400" />}
                    </td>
                    <td className="px-4 py-3 hidden lg:table-cell">
                      {backup.encrypted
                        ? <ShieldCheck className="w-4 h-4 text-emerald-400" />
                        : <span className="text-xs text-muted-foreground">No</span>}
                    </td>
                    <td className="px-4 py-3 text-xs text-muted-foreground">{formatRelativeTime(backup.expiresAt)}</td>
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
