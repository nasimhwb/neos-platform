"use client";

import { Header } from "@/components/layout/Header";
import { StatusBadge } from "@/components/shared/StatusBadge";
import { useApiData } from "@/lib/hooks/useApiData";
import { mockDeployments, mockPlatformInfo } from "@/lib/mock-data";
import { formatDuration, formatRelativeTime } from "@/lib/utils";
import { GitCommit, GitBranch, Clock, User, CheckCircle2, XCircle, RotateCcw } from "lucide-react";
import { useState } from "react";

const colorBadge: Record<string, string> = {
  blue: "bg-blue-500/10 text-blue-400 border-blue-500/20",
  green: "bg-emerald-500/10 text-emerald-400 border-emerald-500/20",
};

export default function DeploymentsPage() {
  const { data: deploymentData, refresh } = useApiData("/api/deployments", {
    platform: mockPlatformInfo,
    history: mockDeployments,
  });

  const [rollingBack, setRollingBack] = useState(false);

  const deployments = deploymentData.history;
  const successCount = deployments.filter(d => d.status === "success").length;
  const failedCount = deployments.filter(d => d.status === "failed").length;

  const handleRollback = async () => {
    if (!confirm("Are you sure you want to rollback to the previous deployment?")) {
      return;
    }
    setRollingBack(true);
    try {
      // Simulate/Trigger Rollback endpoint (logs to Audit)
      const res = await fetch("/api/deployments", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ action: "rollback" }),
      });
      if (res.ok) {
        alert("Rollback initiated. Traffic swapping in progress...");
        refresh();
      } else {
        const err = await res.json();
        alert(`Error: ${err.message || "Failed to trigger rollback"}`);
      }
    } catch (e: any) {
      alert(`Network error: ${e.message}`);
    } finally {
      setRollingBack(false);
    }
  };

  return (
    <div className="flex flex-col h-full">
      <Header title="Deployments" subtitle={`${successCount}/${deployments.length} successful · Blue-Green zero-downtime`} />

      <div className="flex-1 overflow-y-auto p-6 space-y-6">
        {/* Summary */}
        <div className="grid grid-cols-3 gap-4">
          <div className="bg-card border border-border rounded-xl p-4 text-center">
            <p className="text-2xl font-bold text-emerald-400">{successCount}</p>
            <p className="text-xs text-muted-foreground mt-1">Successful</p>
          </div>
          <div className="bg-card border border-border rounded-xl p-4 text-center">
            <p className="text-2xl font-bold text-red-400">{failedCount}</p>
            <p className="text-xs text-muted-foreground mt-1">Failed</p>
          </div>
          <div className="bg-card border border-border rounded-xl p-4 text-center">
            <p className="text-2xl font-bold text-foreground">
              {deployments.length > 0 && successCount > 0 ? Math.round(deployments.filter(d => d.status === "success").reduce((s, d) => s + d.duration, 0) / successCount) : 0}s
            </p>
            <p className="text-xs text-muted-foreground mt-1">Avg Deploy Time</p>
          </div>
        </div>

        {/* Deployment History */}
        <div>
          <div className="flex items-center justify-between mb-3">
            <h2 className="text-sm font-semibold text-muted-foreground uppercase tracking-wider">Deployment History</h2>
            <button
              onClick={handleRollback}
              disabled={rollingBack || deployments.length <= 1}
              className="flex items-center gap-2 text-xs text-muted-foreground hover:text-foreground transition-colors border border-border px-3 py-1.5 rounded-lg hover:bg-muted/30 disabled:opacity-50"
            >
              <RotateCcw className={`w-3.5 h-3.5 ${rollingBack ? "animate-spin" : ""}`} /> 
              {rollingBack ? "Rolling back..." : "Rollback"}
            </button>
          </div>
          <div className="space-y-3">
            {deployments.map(dep => (
              <div key={dep.id} className={`bg-card border rounded-xl p-5 transition-all ${dep.status === "success" ? "border-border" : "border-red-500/20 bg-red-500/5"}`}>
                <div className="flex items-start justify-between mb-3">
                  <div className="flex items-center gap-3">
                    {dep.status === "success"
                      ? <CheckCircle2 className="w-5 h-5 text-emerald-400 flex-shrink-0" />
                      : <XCircle className="w-5 h-5 text-red-400 flex-shrink-0" />}
                    <div>
                      <p className="font-mono text-sm font-semibold text-foreground">{dep.releaseId}</p>
                      {dep.notes && <p className="text-xs text-muted-foreground mt-0.5">{dep.notes}</p>}
                    </div>
                  </div>
                  <div className="flex items-center gap-2">
                    <span className={`text-xs font-medium px-2 py-0.5 rounded-full border ${colorBadge[dep.color] || "text-slate-400 border-slate-700 bg-slate-800/10"}`}>
                      {dep.color}
                    </span>
                    <StatusBadge status={dep.status} />
                  </div>
                </div>

                <div className="grid grid-cols-2 md:grid-cols-4 gap-3 text-xs text-muted-foreground">
                  <div className="flex items-center gap-1.5">
                    <GitCommit className="w-3.5 h-3.5" />
                    <code className="font-mono">{dep.gitCommit}</code>
                  </div>
                  <div className="flex items-center gap-1.5">
                    <GitBranch className="w-3.5 h-3.5" />
                    <span>{dep.gitBranch}</span>
                  </div>
                  <div className="flex items-center gap-1.5">
                    <Clock className="w-3.5 h-3.5" />
                    <span>{formatDuration(dep.duration)} · {dep.healthChecks} checks</span>
                  </div>
                  <div className="flex items-center gap-1.5">
                    <User className="w-3.5 h-3.5" />
                    <span>{dep.triggeredBy} · {formatRelativeTime(dep.timestamp)}</span>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
