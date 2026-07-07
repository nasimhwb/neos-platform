import { Header } from "@/components/layout/Header";
import { StatusBadge } from "@/components/shared/StatusBadge";
import { mockSSLCerts } from "@/lib/mock-data";
import { Shield, RefreshCw, AlertTriangle } from "lucide-react";
import { cn } from "@/lib/utils";

export default function SSLPage() {
  const certs = mockSSLCerts;
  const expiringSoon = certs.filter(c => c.daysRemaining < 30).length;

  return (
    <div className="flex flex-col h-full">
      <Header title="SSL Certificates" subtitle="Let's Encrypt ACME via Traefik · Auto-renewal enabled" />

      <div className="flex-1 overflow-y-auto p-6 space-y-6">
        {/* Summary */}
        <div className="grid grid-cols-3 gap-4">
          <div className="bg-card border border-border rounded-xl p-4 text-center">
            <p className="text-2xl font-bold text-emerald-400">{certs.filter(c => c.status === "valid").length}</p>
            <p className="text-xs text-muted-foreground mt-1">Valid</p>
          </div>
          <div className="bg-card border border-border rounded-xl p-4 text-center">
            <p className="text-2xl font-bold text-amber-400">{expiringSoon}</p>
            <p className="text-xs text-muted-foreground mt-1">Expiring Soon (&lt;30d)</p>
          </div>
          <div className="bg-card border border-border rounded-xl p-4 text-center">
            <p className="text-2xl font-bold text-red-400">{certs.filter(c => c.status === "expired").length}</p>
            <p className="text-xs text-muted-foreground mt-1">Expired</p>
          </div>
        </div>

        {/* Expiring Warning */}
        {expiringSoon > 0 && (
          <div className="flex items-center gap-3 bg-amber-500/10 border border-amber-500/20 rounded-xl px-4 py-3">
            <AlertTriangle className="w-4 h-4 text-amber-400 flex-shrink-0" />
            <p className="text-sm text-amber-300">
              {expiringSoon} certificate{expiringSoon > 1 ? "s" : ""} expiring within 30 days. Traefik will auto-renew if DNS resolves correctly.
            </p>
          </div>
        )}

        {/* Certificate Table */}
        <div>
          <h2 className="text-sm font-semibold text-muted-foreground uppercase tracking-wider mb-3 flex items-center gap-2">
            <Shield className="w-4 h-4" /> Certificates
          </h2>
          <div className="bg-card border border-border rounded-xl overflow-hidden">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-border bg-muted/30">
                  <th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground">Domain</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground">Status</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground">Days Left</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground hidden md:table-cell">Issuer</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground hidden md:table-cell">Expires</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground">Auto-Renew</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {certs.map(cert => (
                  <tr key={cert.domain} className="hover:bg-muted/20 transition-colors">
                    <td className="px-4 py-3 font-mono text-sm text-foreground">{cert.domain}</td>
                    <td className="px-4 py-3"><StatusBadge status={cert.status} /></td>
                    <td className="px-4 py-3">
                      <span className={cn("text-sm font-semibold",
                        cert.daysRemaining > 30 ? "text-emerald-400"
                          : cert.daysRemaining > 7 ? "text-amber-400"
                            : "text-red-400"
                      )}>
                        {cert.daysRemaining}d
                      </span>
                    </td>
                    <td className="px-4 py-3 text-xs text-muted-foreground hidden md:table-cell">{cert.issuer}</td>
                    <td className="px-4 py-3 text-xs text-muted-foreground hidden md:table-cell">
                      {new Date(cert.validTo).toLocaleDateString()}
                    </td>
                    <td className="px-4 py-3">
                      {cert.autoRenew
                        ? <RefreshCw className="w-4 h-4 text-emerald-400" />
                        : <span className="text-xs text-muted-foreground">Manual</span>}
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
