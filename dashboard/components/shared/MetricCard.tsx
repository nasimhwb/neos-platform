import { cn, getUsageColor } from "@/lib/utils";
import type { LucideIcon } from "lucide-react";

interface MetricCardProps {
  title: string;
  value: React.ReactNode;
  subtitle?: string;
  icon?: LucideIcon;
  trend?: "up" | "down" | "neutral";
  usagePercent?: number;
  className?: string;
}

export function MetricCard({ title, value, subtitle, icon: Icon, usagePercent, className }: MetricCardProps) {
  return (
    <div className={cn(
      "bg-card border border-border rounded-xl p-4 flex flex-col gap-3 hover:border-border/60 transition-colors",
      className
    )}>
      <div className="flex items-center justify-between">
        <p className="text-xs font-medium text-muted-foreground uppercase tracking-wider">{title}</p>
        {Icon && (
          <div className="w-8 h-8 rounded-lg bg-muted/50 flex items-center justify-center">
            <Icon className="w-4 h-4 text-muted-foreground" />
          </div>
        )}
      </div>
      <div>
        <p className="text-2xl font-bold text-foreground">{value}</p>
        {subtitle && <p className="text-xs text-muted-foreground mt-0.5">{subtitle}</p>}
      </div>
      {usagePercent !== undefined && (
        <div className="space-y-1">
          <div className="w-full bg-muted rounded-full h-1.5 overflow-hidden">
            <div
              className={cn("h-full rounded-full transition-all", getUsageColor(usagePercent))}
              style={{ width: `${Math.min(usagePercent, 100)}%` }}
            />
          </div>
          <p className="text-xs text-muted-foreground">{usagePercent.toFixed(1)}% used</p>
        </div>
      )}
    </div>
  );
}
