"use client";

import { cn } from "@/lib/utils";

interface AgentAvatarProps {
  name: string;
  color: string;
  size?: "sm" | "md" | "lg";
  isOnline?: boolean;
  className?: string;
}

const colorMap: Record<string, string> = {
  purple: "bg-[#7F77DD]",
  teal: "bg-[#1D9E75]",
  amber: "bg-[#EF9F27]",
  coral: "bg-[#D85A30]",
  blue: "bg-[#378ADD]",
  gray: "bg-[#888780]",
};

const sizeMap = {
  sm: "w-6 h-6 text-[10px]",
  md: "w-8 h-8 text-xs",
  lg: "w-10 h-10 text-sm",
};

export function AgentAvatar({ name, color, size = "md", isOnline, className }: AgentAvatarProps) {
  const initials = name.slice(0, 2).toUpperCase();
  return (
    <div className={cn("relative inline-flex", className)}>
      <div
        className={cn(
          "rounded-full flex items-center justify-center font-semibold text-white/90",
          colorMap[color] || "bg-[#888780]",
          sizeMap[size]
        )}
      >
        {initials}
      </div>
      {isOnline !== undefined && (
        <span
          className={cn(
            "absolute -bottom-0.5 -right-0.5 rounded-full border-2 border-[#0a0a0a]",
            size === "sm" ? "w-2 h-2" : "w-2.5 h-2.5",
            isOnline ? "bg-[#1D9E75]" : "bg-[#888780]"
          )}
        />
      )}
    </div>
  );
}
