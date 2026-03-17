import { cn } from "@/lib/utils";

type BadgeVariant = "PENDING" | "RUNNING" | "COMPLETED" | "FAILED" | "CANCELLED" |
  "CTO" | "BACKEND" | "FRONTEND" | "QA" | "SUPPORT" | "CM" | "MAPPER" | "BALANCER" | "DEVOPS" | "RESEARCH" |
  "implemented" | "pending" | "online" | "offline" | "busy";

const variantStyles: Record<string, string> = {
  PENDING: "bg-[#EF9F27]/15 text-[#EF9F27] border-[#EF9F27]/20",
  RUNNING: "bg-[#378ADD]/15 text-[#378ADD] border-[#378ADD]/20",
  COMPLETED: "bg-[#1D9E75]/15 text-[#1D9E75] border-[#1D9E75]/20",
  FAILED: "bg-[#D85A30]/15 text-[#D85A30] border-[#D85A30]/20",
  CANCELLED: "bg-[#888780]/15 text-[#888780] border-[#888780]/20",
  CTO: "bg-[#7F77DD]/15 text-[#7F77DD] border-[#7F77DD]/20",
  BACKEND: "bg-[#1D9E75]/15 text-[#1D9E75] border-[#1D9E75]/20",
  FRONTEND: "bg-[#378ADD]/15 text-[#378ADD] border-[#378ADD]/20",
  QA: "bg-[#EF9F27]/15 text-[#EF9F27] border-[#EF9F27]/20",
  SUPPORT: "bg-[#D85A30]/15 text-[#D85A30] border-[#D85A30]/20",
  CM: "bg-[#EF9F27]/15 text-[#EF9F27] border-[#EF9F27]/20",
  MAPPER: "bg-[#D85A30]/15 text-[#D85A30] border-[#D85A30]/20",
  BALANCER: "bg-[#888780]/15 text-[#888780] border-[#888780]/20",
  DEVOPS: "bg-[#888780]/15 text-[#888780] border-[#888780]/20",
  RESEARCH: "bg-[#7F77DD]/15 text-[#7F77DD] border-[#7F77DD]/20",
  implemented: "bg-[#1D9E75]/15 text-[#1D9E75] border-[#1D9E75]/20",
  pending: "bg-[#EF9F27]/15 text-[#EF9F27] border-[#EF9F27]/20",
  online: "bg-[#1D9E75]/15 text-[#1D9E75] border-[#1D9E75]/20",
  offline: "bg-[#888780]/15 text-[#888780] border-[#888780]/20",
  busy: "bg-[#EF9F27]/15 text-[#EF9F27] border-[#EF9F27]/20",
};

interface StatusBadgeProps {
  variant: BadgeVariant;
  label?: string;
  className?: string;
}

export function StatusBadge({ variant, label, className }: StatusBadgeProps) {
  return (
    <span
      className={cn(
        "inline-flex items-center px-2 py-0.5 rounded-full text-[11px] font-medium border",
        variantStyles[variant] || variantStyles.offline,
        className
      )}
    >
      {label || variant}
    </span>
  );
}
