import { Header } from "@/components/layout/Header";
import { Settings, Globe, Mail, Database, Shield, ToggleLeft } from "lucide-react";

const envVars = [
  { key: "ENVIRONMENT", value: "production", masked: false },
  { key: "BASE_DOMAIN", value: "neos-platform.local", masked: false },
  { key: "ACME_EMAIL", value: "admin@neos-platform.local", masked: false },
  { key: "POSTGRES_VERSION", value: "16.3-alpine", masked: false },
  { key: "POSTGRES_SUPERUSER_PASSWORD", value: "••••••••••••••••", masked: true },
  { key: "REDIS_VERSION", value: "8.0-M02-alpine", masked: false },
  { key: "REDIS_PASSWORD", value: "••••••••••••••••", masked: true },
  { key: "MINIO_ROOT_USER", value: "neos_storage_admin", masked: false },
  { key: "MINIO_ROOT_PASSWORD", value: "••••••••••••••••", masked: true },
  { key: "JWT_SECRET", value: "••••••••••••••••", masked: true },
  { key: "BACKUP_RETENTION_DAYS", value: "14", masked: false },
  { key: "GRAFANA_VERSION", value: "11.0.0", masked: false },
];

const platformSettings = [
  { label: "Platform Name", value: "NEOS Platform", icon: Globe },
  { label: "Environment", value: "production", icon: Globe },
  { label: "Base Domain", value: "neos-platform.local", icon: Globe },
  { label: "ACME Email", value: "admin@neos-platform.local", icon: Mail },
  { label: "PostgreSQL Version", value: "16.3-alpine", icon: Database },
  { label: "Backup Retention", value: "14 days", icon: Shield },
];

export default function SettingsPage() {
  return (
    <div className="flex flex-col h-full">
      <Header title="Settings" subtitle="Platform configuration and environment variables" />

      <div className="flex-1 overflow-y-auto p-6 space-y-6">
        {/* Platform Settings */}
        <div>
          <h2 className="text-sm font-semibold text-muted-foreground uppercase tracking-wider mb-3 flex items-center gap-2">
            <Settings className="w-4 h-4" /> Platform Settings
          </h2>
          <div className="bg-card border border-border rounded-xl divide-y divide-border">
            {platformSettings.map(setting => (
              <div key={setting.label} className="flex items-center justify-between px-5 py-3 hover:bg-muted/20 transition-colors">
                <div className="flex items-center gap-3">
                  <setting.icon className="w-4 h-4 text-muted-foreground" />
                  <span className="text-sm text-muted-foreground">{setting.label}</span>
                </div>
                <span className="text-sm font-medium text-foreground font-mono">{setting.value}</span>
              </div>
            ))}
          </div>
        </div>

        {/* Maintenance Mode */}
        <div className="bg-card border border-border rounded-xl p-5 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <ToggleLeft className="w-5 h-5 text-muted-foreground" />
            <div>
              <p className="text-sm font-medium text-foreground">Maintenance Mode</p>
              <p className="text-xs text-muted-foreground">Enables a platform-wide maintenance banner and restricts access</p>
            </div>
          </div>
          <div className="flex items-center gap-2">
            <span className="text-xs text-muted-foreground">Disabled</span>
            <div className="w-10 h-5 rounded-full bg-muted border border-border cursor-pointer relative">
              <div className="absolute top-0.5 left-0.5 w-4 h-4 rounded-full bg-muted-foreground/50 transition-all" />
            </div>
          </div>
        </div>

        {/* Environment Variables */}
        <div>
          <h2 className="text-sm font-semibold text-muted-foreground uppercase tracking-wider mb-3">
            Environment Variables
          </h2>
          <div className="bg-card border border-border rounded-xl overflow-hidden">
            <table className="w-full text-sm font-mono">
              <thead>
                <tr className="border-b border-border bg-muted/30">
                  <th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground not-italic">Variable</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground not-italic">Value</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground not-italic hidden md:table-cell">Masked</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {envVars.map(env => (
                  <tr key={env.key} className="hover:bg-muted/20 transition-colors">
                    <td className="px-4 py-2.5 text-xs text-blue-400">{env.key}</td>
                    <td className="px-4 py-2.5 text-xs text-foreground">{env.value}</td>
                    <td className="px-4 py-2.5 hidden md:table-cell">
                      {env.masked
                        ? <span className="text-xs text-amber-400">🔒 masked</span>
                        : <span className="text-xs text-muted-foreground">—</span>}
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
