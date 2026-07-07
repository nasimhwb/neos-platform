"use client";

import { Header } from "@/components/layout/Header";
import { StatusBadge } from "@/components/shared/StatusBadge";
import { useApiData } from "@/lib/hooks/useApiData";
import { mockApplications } from "@/lib/mock-data";
import { formatRelativeTime } from "@/lib/utils";
import { ExternalLink, RotateCcw, FileText, Globe, Database, Zap } from "lucide-react";
import { useState } from "react";

export default function ApplicationsPage() {
  const { data: apps, refresh } = useApiData("/api/applications", mockApplications);
  const [restartingId, setRestartingId] = useState<string | null>(null);

  const running = apps.filter(a => a.status === "healthy").length;
  const degraded = apps.filter(a => a.status === "degraded").length;
  const unhealthy = apps.filter(a => a.status === "unhealthy").length;

  const handleRestart = async (containerName: string) => {
    setRestartingId(containerName);
    try {
      const res = await fetch("/api/docker", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ id: containerName, action: "restart" }),
      });
      if (res.ok) {
        alert(`Restart command sent to container ${containerName}`);
        refresh();
      } else {
        const err = await res.json();
        alert(`Error: ${err.message || "Failed to restart container"}`);
      }
    } catch (e: any) {
      alert(`Network error: ${e.message}`);
    } finally {
      setRestartingId(null);
    }
  };

  return (
    <div className="flex flex-col h-full">
      <Header title="Applications" subtitle={`${running} healthy · ${degraded} degraded · ${unhealthy} unhealthy`} />

      <div className="flex-1 overflow-y-auto p-6 space-y-4">
        {/* Summary row */}
        <div className="grid grid-cols-3 gap-4">
          <div className="bg-card border border-border rounded-xl p-4 text-center">
            <p className="text-2xl font-bold text-emerald-400">{running}</p>
            <p className="text-xs text-muted-foreground mt-1">Healthy</p>
          </div>
          <div className="bg-card border border-border rounded-xl p-4 text-center">
            <p className="text-2xl font-bold text-amber-400">{degraded}</p>
            <p className="text-xs text-muted-foreground mt-1">Degraded</p>
          </div>
          <div className="bg-card border border-border rounded-xl p-4 text-center">
            <p className="text-2xl font-bold text-red-400">{unhealthy}</p>
            <p className="text-xs text-muted-foreground mt-1">Unhealthy</p>
          </div>
        </div>

        {/* Application cards */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
          {apps.map(app => (
            <div
              key={app.id}
              className="bg-card border border-border rounded-xl p-5 hover:border-border/60 transition-all"
            >
              <div className="flex items-start justify-between mb-4">
                <div>
                  <div className="flex items-center gap-2 mb-1">
                    <h3 className="font-semibold text-foreground">{app.displayName}</h3>
                    <StatusBadge status={app.status} />
                  </div>
                  <p className="text-xs text-muted-foreground">{app.description}</p>
                </div>
                <span className="text-xs font-mono text-muted-foreground bg-muted/50 px-2 py-0.5 rounded">
                  v{app.version}
                </span>
              </div>

              <div className="grid grid-cols-2 gap-y-2 text-xs mb-4">
                <div className="flex items-center gap-2 text-muted-foreground col-span-2">
                  <Globe className="w-3.5 h-3.5" />
                  <a href={`https://${app.domain}`} target="_blank" rel="noopener noreferrer"
                    className="hover:text-foreground transition-colors truncate">{app.domain}</a>
                </div>
                <div className="flex items-center gap-2 text-muted-foreground col-span-2">
                  <span className="font-mono">{app.container}</span>
                </div>
                {app.dbName && (
                  <div className="flex items-center gap-2 text-muted-foreground col-span-1">
                    <Database className="w-3.5 h-3.5" />
                    <span className="font-mono">{app.dbName}</span>
                  </div>
                )}
                {app.redisDb !== undefined && (
                  <div className="flex items-center gap-2 text-muted-foreground col-span-1">
                    <Zap className="w-3.5 h-3.5" />
                    <span className="font-mono">redis:{app.redisDb}</span>
                  </div>
                )}
              </div>

              <div className="flex items-center justify-between pt-3 border-t border-border">
                <span className="text-xs text-muted-foreground">
                  Deployed {formatRelativeTime(app.lastDeployment)}
                </span>
                <div className="flex items-center gap-1">
                  <button 
                    onClick={() => handleRestart(app.container)}
                    disabled={restartingId === app.container}
                    className="p-1.5 rounded-md hover:bg-muted/50 transition-colors text-muted-foreground hover:text-foreground cursor-pointer disabled:opacity-50"
                    title="Restart"
                  >
                    <RotateCcw className={`w-3.5 h-3.5 ${restartingId === app.container ? "animate-spin" : ""}`} />
                  </button>
                  <a href={`/logs?source=${app.container}`}
                    className="p-1.5 rounded-md hover:bg-muted/50 transition-colors text-muted-foreground hover:text-foreground" 
                    title="View Logs"
                  >
                    <FileText className="w-3.5 h-3.5" />
                  </a>
                  <a href={`https://${app.domain}`} target="_blank" rel="noopener noreferrer"
                    className="p-1.5 rounded-md hover:bg-muted/50 transition-colors text-muted-foreground hover:text-foreground" 
                    title="Open App"
                  >
                    <ExternalLink className="w-3.5 h-3.5" />
                  </a>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
