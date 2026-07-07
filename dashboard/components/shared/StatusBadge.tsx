import { cn, getStatusBgColor } from "@/lib/utils";

interface StatusBadgeProps {
  status: string;
  className?: string;
}

export function StatusBadge({ status, className }: StatusBadgeProps) {
  return (
    <span className={cn(
      "inline-flex items-center gap-1.5 px-2 py-0.5 text-xs font-medium rounded-full border capitalize",
      getStatusBgColor(status),
      className
    )}>
      <span className={cn(
        "w-1.5 h-1.5 rounded-full",
        status === "healthy" || status === "running" || status === "success" || status === "up" || status === "valid"
          ? "bg-emerald-400 animate-pulse"
          : status === "degraded" || status === "warning" || status === "expiring"
            ? "bg-amber-400"
            : status === "unhealthy" || status === "stopped" || status === "failed" || status === "down"
              ? "bg-red-400"
              : "bg-slate-400"
      )} />
      {status}
    </span>
  );
}
