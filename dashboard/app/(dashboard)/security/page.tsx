import { Header } from "@/components/layout/Header";
import { mockFirewallRules, mockSecurityEvents } from "@/lib/mock-data";
import { cn, formatRelativeTime } from "@/lib/utils";
import { Shield, AlertTriangle, Info, Lock } from "lucide-react";

const severityIcon: Record<string, React.ReactNode> = {
  critical: <AlertTriangle className="w-4 h-4 text-red-400" />,
  warning: <AlertTriangle className="w-4 h-4 text-amber-400" />,
  info: <Info className="w-4 h-4 text-blue-400" />,
};

export default function SecurityPage() {
  const rules = mockFirewallRules;
  const events = mockSecurityEvents;
  const blocked = events.filter(e => e.type === "blocked").length;

  return (
    <div className="flex flex-col h-full">
      <Header title="Security" subtitle="Firewall · Fail2Ban · SSH · Open Ports" />

      <div className="flex-1 overflow-y-auto p-6 space-y-6">
        {/* Summary */}
        <div className="grid grid-cols-3 gap-4">
          <div className="bg-card border border-border rounded-xl p-4 text-center">
            <p className="text-2xl font-bold text-emerald-400">{rules.filter(r => r.action === "allow").length}</p>
            <p className="text-xs text-muted-foreground mt-1">Open Rules</p>
          </div>
          <div className="bg-card border border-border rounded-xl p-4 text-center">
            <p className="text-2xl font-bold text-red-400">{rules.filter(r => r.action === "deny").length}</p>
            <p className="text-xs text-muted-foreground mt-1">Denied Rules</p>
          </div>
          <div className="bg-card border border-border rounded-xl p-4 text-center">
            <p className="text-2xl font-bold text-amber-400">{blocked}</p>
            <p className="text-xs text-muted-foreground mt-1">Blocked (24h)</p>
          </div>
        </div>

        {/* Firewall Rules */}
        <div>
          <h2 className="text-sm font-semibold text-muted-foreground uppercase tracking-wider mb-3 flex items-center gap-2">
            <Shield className="w-4 h-4" /> UFW Firewall Rules
          </h2>
          <div className="bg-card border border-border rounded-xl overflow-hidden">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-border bg-muted/30">
                  <th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground">Port</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground">Protocol</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground">Action</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground hidden md:table-cell">From</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground">Comment</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {rules.map((rule, i) => (
                  <tr key={i} className="hover:bg-muted/20 transition-colors">
                    <td className="px-4 py-3 font-mono text-sm text-foreground">{rule.port}</td>
                    <td className="px-4 py-3 text-xs text-muted-foreground uppercase">{rule.protocol}</td>
                    <td className="px-4 py-3">
                      <span className={cn("text-xs font-semibold",
                        rule.action === "allow" ? "text-emerald-400" : "text-red-400"
                      )}>
                        {rule.action.toUpperCase()}
                      </span>
                    </td>
                    <td className="px-4 py-3 text-xs font-mono text-muted-foreground hidden md:table-cell">{rule.from}</td>
                    <td className="px-4 py-3 text-xs text-muted-foreground">{rule.comment}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>

        {/* Security Events */}
        <div>
          <h2 className="text-sm font-semibold text-muted-foreground uppercase tracking-wider mb-3 flex items-center gap-2">
            <Lock className="w-4 h-4" /> Recent Security Events
          </h2>
          <div className="space-y-2">
            {events.map((event, i) => (
              <div key={i} className="bg-card border border-border rounded-xl px-4 py-3 flex items-start gap-3">
                <div className="mt-0.5">{severityIcon[event.severity]}</div>
                <div className="flex-1">
                  <div className="flex items-center gap-2 mb-0.5">
                    <span className="font-mono text-sm text-foreground">{event.ip}</span>
                    <span className="text-xs uppercase text-muted-foreground bg-muted/50 px-1.5 py-0.5 rounded">{event.type}</span>
                  </div>
                  <p className="text-xs text-muted-foreground">{event.details}</p>
                </div>
                <span className="text-xs text-muted-foreground flex-shrink-0">{formatRelativeTime(event.timestamp)}</span>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
