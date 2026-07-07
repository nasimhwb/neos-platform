"use client";

import { Header } from "@/components/layout/Header";
import { StatusBadge } from "@/components/shared/StatusBadge";
import { useApiData } from "@/lib/hooks/useApiData";
import { mockUsers } from "@/lib/mock-data";
import { formatRelativeTime } from "@/lib/utils";
import { Users as UsersIcon, UserPlus, ShieldCheck } from "lucide-react";

const roleColors: Record<string, string> = {
  admin: "bg-red-500/10 text-red-400 border-red-500/20",
  operator: "bg-blue-500/10 text-blue-400 border-blue-500/20",
  viewer: "bg-slate-500/10 text-slate-400 border-slate-500/20",
};

export default function UsersPage() {
  const { data: users } = useApiData("/api/users", mockUsers);

  return (
    <div className="flex flex-col h-full">
      <Header title="Platform Users" subtitle="Role-based access control · SSO-ready" />

      <div className="flex-1 overflow-y-auto p-6 space-y-6">
        {/* Summary */}
        <div className="grid grid-cols-3 gap-4">
          {["admin", "operator", "viewer"].map(role => (
            <div key={role} className="bg-card border border-border rounded-xl p-4 text-center">
              <p className="text-2xl font-bold text-foreground">{users.filter(u => u.role === role).length}</p>
              <p className="text-xs text-muted-foreground mt-1 capitalize">{role}s</p>
            </div>
          ))}
        </div>

        {/* User Table */}
        <div>
          <div className="flex items-center justify-between mb-3">
            <h2 className="text-sm font-semibold text-muted-foreground uppercase tracking-wider flex items-center gap-2">
              <UsersIcon className="w-4 h-4" /> All Users
            </h2>
            <button className="flex items-center gap-2 text-xs text-muted-foreground hover:text-foreground transition-colors border border-border px-3 py-1.5 rounded-lg hover:bg-muted/30">
              <UserPlus className="w-3.5 h-3.5" /> Invite User
            </button>
          </div>
          <div className="bg-card border border-border rounded-xl overflow-hidden">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-border bg-muted/30">
                  <th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground">User</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground">Role</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground">Status</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground hidden md:table-cell">Last Login</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground hidden md:table-cell">Created</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {users.map(user => (
                  <tr key={user.id} className="hover:bg-muted/20 transition-colors">
                    <td className="px-4 py-3">
                      <div className="flex items-center gap-3">
                        <div className="w-7 h-7 rounded-full bg-primary/20 flex items-center justify-center text-xs font-semibold text-primary">
                          {user.name[0]}
                        </div>
                        <div>
                          <p className="text-sm font-medium text-foreground">{user.name}</p>
                          <p className="text-xs text-muted-foreground">{user.email}</p>
                        </div>
                      </div>
                    </td>
                    <td className="px-4 py-3">
                      <span className={`inline-flex items-center gap-1 text-xs font-medium px-2 py-0.5 rounded-full border ${roleColors[user.role] || "text-slate-400 border-slate-700 bg-slate-800/10"}`}>
                        <ShieldCheck className="w-3 h-3" /> {user.role}
                      </span>
                    </td>
                    <td className="px-4 py-3">
                      <StatusBadge status={user.active ? "healthy" : "stopped"} />
                    </td>
                    <td className="px-4 py-3 text-xs text-muted-foreground hidden md:table-cell">
                      {formatRelativeTime(user.lastLogin)}
                    </td>
                    <td className="px-4 py-3 text-xs text-muted-foreground hidden md:table-cell">
                      {formatRelativeTime(user.createdAt)}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>

        {/* RBAC Info */}
        <div className="bg-card border border-border rounded-xl p-5">
          <h3 className="text-sm font-semibold text-foreground mb-3">Role Permissions</h3>
          <div className="overflow-x-auto">
            <table className="w-full text-xs">
              <thead>
                <tr className="border-b border-border">
                  <th className="text-left py-2 pr-4 text-muted-foreground">Permission</th>
                  <th className="text-center py-2 px-3 text-red-400">Admin</th>
                  <th className="text-center py-2 px-3 text-blue-400">Operator</th>
                  <th className="text-center py-2 px-3 text-slate-400">Viewer</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border/50">
                {[
                  ["View Dashboard", true, true, true],
                  ["Restart Containers", true, true, false],
                  ["Trigger Deployments", true, true, false],
                  ["Rollback Releases", true, true, false],
                  ["Manage Users", true, false, false],
                  ["Edit Settings", true, false, false],
                  ["View Secrets", true, false, false],
                ].map(([perm, admin, op, viewer]) => (
                  <tr key={String(perm)} className="hover:bg-muted/10">
                    <td className="py-2 pr-4 text-muted-foreground">{String(perm)}</td>
                    <td className="text-center py-2 px-3">{admin ? "✓" : "—"}</td>
                    <td className="text-center py-2 px-3">{op ? "✓" : "—"}</td>
                    <td className="text-center py-2 px-3">{viewer ? "✓" : "—"}</td>
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
