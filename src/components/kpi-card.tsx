import { cn } from "@/lib/utils";
import { LucideIcon } from "lucide-react";

interface KpiCardProps {
  label: string;
  value: string;
  trend?: string;
  trendUp?: boolean;
  icon?: LucideIcon;
  accentColor?: string;
  progress?: number; // 0-100
  className?: string;
}

export function KpiCard({
  label,
  value,
  trend,
  trendUp,
  icon: Icon,
  accentColor = "#888780",
  progress,
  className,
}: KpiCardProps) {
  return (
    <div
      className={cn(
        "relative bg-[#111111] border border-[#222222] rounded-lg p-5 overflow-hidden group hover:border-[#333333] transition-colors",
        className
      )}
    >
      <div className="absolute top-0 left-0 w-1 h-full" style={{ backgroundColor: accentColor }} />
      <div className="flex items-start justify-between">
        <div>
          <p className="text-xs text-[#888780] uppercase tracking-wider mb-1">{label}</p>
          <p className="text-2xl font-semibold text-white">{value}</p>
          {trend && (
            <p
              className={cn(
                "text-xs mt-1 font-medium",
                trendUp ? "text-[#1D9E75]" : "text-[#D85A30]"
              )}
            >
              {trendUp ? "↑" : "↓"} {trend}
            </p>
          )}
        </div>
        {Icon && (
          <Icon className="w-5 h-5 text-[#888780] opacity-50 group-hover:opacity-80 transition-opacity" />
        )}
      </div>
      {progress !== undefined && (
        <div className="mt-3">
          <div className="w-full h-1.5 bg-[#1a1a1a] rounded-full overflow-hidden">
            <div
              className="h-full rounded-full transition-all duration-500"
              style={{
                width: `${Math.min(progress, 100)}%`,
                backgroundColor: accentColor,
              }}
            />
          </div>
        </div>
      )}
    </div>
  );
}
