import { Header } from "@/components/layout/Header";
import { StatusBadge } from "@/components/shared/StatusBadge";
import { mockDockerStatus, mockContainers, mockNetworks, mockVolumes } from "@/lib/mock-data";
import { formatBytes, formatRelativeTime } from "@/lib/utils";
import { Container, Network, HardDrive, Activity } from "lucide-react";

export default function InfrastructurePage() {
  const docker = mockDockerStatus;
  const containers = mockContainers;
  const networks = mockNetworks;
  const volumes = mockVolumes;

  return (
    <div className="flex flex-col h-full">
      <Header title="Infrastructure" subtitle="Docker Engine, Networks, Volumes, and Containers" />

      <div className="flex-1 overflow-y-auto p-6 space-y-6">
        {/* Docker Engine Summary */}
        <div>
          <h2 className="text-sm font-semibold text-muted-foreground uppercase tracking-wider mb-3">Docker Engine</h2>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            {[
              { label: "Running", value: docker.containers.running, icon: Container, color: "text-emerald-400" },
              { label: "Stopped", value: docker.containers.stopped, icon: Container, color: "text-slate-400" },
              { label: "Images", value: docker.images, icon: Activity, color: "text-blue-400" },
              { label: "Volumes", value: docker.volumes, icon: HardDrive, color: "text-purple-400" },
            ].map(item => (
              <div key={item.label} className="bg-card border border-border rounded-xl p-4">
                <div className="flex items-center gap-2 mb-2">
                  <item.icon className={`w-4 h-4 ${item.color}`} />
                  <span className="text-xs text-muted-foreground">{item.label}</span>
                </div>
                <p className={`text-2xl font-bold ${item.color}`}>{item.value}</p>
              </div>
            ))}
          </div>
        </div>

        {/* Containers Table */}
        <div>
          <h2 className="text-sm font-semibold text-muted-foreground uppercase tracking-wider mb-3">Containers</h2>
          <div className="bg-card border border-border rounded-xl overflow-hidden">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-border bg-muted/30">
                  <th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground">Name</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground">Image</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground">State</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground hidden md:table-cell">CPU</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground hidden md:table-cell">Memory</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground hidden lg:table-cell">Ports</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {containers.map(c => (
                  <tr key={c.id} className="hover:bg-muted/20 transition-colors">
                    <td className="px-4 py-3 font-mono text-xs text-foreground">{c.name}</td>
                    <td className="px-4 py-3 font-mono text-xs text-muted-foreground truncate max-w-[140px]">{c.image}</td>
                    <td className="px-4 py-3"><StatusBadge status={c.state === "running" ? "healthy" : c.state === "exited" || c.state === "stopped" ? "stopped" : "degraded"} /></td>
                    <td className="px-4 py-3 text-xs text-muted-foreground hidden md:table-cell">{c.cpuUsage.toFixed(1)}%</td>
                    <td className="px-4 py-3 text-xs text-muted-foreground hidden md:table-cell">{formatBytes(c.memoryUsage)}</td>
                    <td className="px-4 py-3 text-xs font-mono text-muted-foreground hidden lg:table-cell">
                      {c.ports.length > 0 ? c.ports.join(", ") : "—"}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>

        {/* Networks + Volumes */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <div>
            <h2 className="text-sm font-semibold text-muted-foreground uppercase tracking-wider mb-3 flex items-center gap-2">
              <Network className="w-4 h-4" /> Networks
            </h2>
            <div className="bg-card border border-border rounded-xl overflow-hidden">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-border bg-muted/30">
                    <th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground">Name</th>
                    <th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground">Driver</th>
                    <th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground">Subnet</th>
                    <th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground">Containers</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-border">
                  {networks.map(n => (
                    <tr key={n.id} className="hover:bg-muted/20 transition-colors">
                      <td className="px-4 py-3 font-mono text-xs text-foreground">{n.name}</td>
                      <td className="px-4 py-3 text-xs text-muted-foreground">{n.driver}</td>
                      <td className="px-4 py-3 font-mono text-xs text-muted-foreground">{n.subnet}</td>
                      <td className="px-4 py-3 text-xs text-muted-foreground">{n.containers}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>

          <div>
            <h2 className="text-sm font-semibold text-muted-foreground uppercase tracking-wider mb-3 flex items-center gap-2">
              <HardDrive className="w-4 h-4" /> Volumes
            </h2>
            <div className="bg-card border border-border rounded-xl overflow-hidden">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-border bg-muted/30">
                    <th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground">Name</th>
                    <th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground">Size</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-border">
                  {volumes.map(v => (
                    <tr key={v.name} className="hover:bg-muted/20 transition-colors">
                      <td className="px-4 py-3">
                        <p className="font-mono text-xs text-foreground">{v.name}</p>
                        <p className="text-xs text-muted-foreground truncate max-w-[200px]">{v.mountpoint}</p>
                      </td>
                      <td className="px-4 py-3 text-xs text-muted-foreground">{formatBytes(v.usageBytes)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
