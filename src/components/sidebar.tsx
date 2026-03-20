"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { useEffect, useState } from "react";
import { cn } from "@/lib/utils";
import {
  LayoutDashboard, Bot, ListTodo, DollarSign, Users, Cpu,
  Map, Sword, Bug, ScrollText, Settings, Zap
} from "lucide-react";
import { backendApi } from "@/lib/api";

interface Agent {
  slug: string;
  displayName: string;
  isOnline: boolean;
  color: string;
  role: string;
}

const roleLabels: Record<string, string> = {
  CTO: "CTO",
  BACKEND: "Lua Dev",
  LUA_DEV: "Lua Dev",
  FRONTEND: "C++ Dev",
  CPP_DEV: "C++ Dev",
  QA: "QA Engineer",
  SUPPORT: "Support",
  CM: "CM",
  MAPPER: "Mapper",
  BALANCER: "Balancer",
  DEVOPS: "DevOps",
  RESEARCH: "Research",
};

const navItems = [
  { href: "/", label: "Overview", icon: LayoutDashboard },
  { href: "/agents", label: "Agents", icon: Bot },
  { href: "/tasks", label: "Tasks", icon: ListTodo },
  { href: "/revenue", label: "Revenue", icon: DollarSign },
  { href: "/players", label: "Players", icon: Users },
  { href: "/systems", label: "Systems", icon: Cpu },
  { href: "/roadmap", label: "Roadmap", icon: Map },
  { href: "/integrations", label: "Integrations", icon: Zap },
  { href: "/logs", label: "Logs", icon: ScrollText },
  { href: "/settings", label: "Settings", icon: Settings },
];

const agentColorMap: Record<string, string> = {
  purple: "#7F77DD", teal: "#1D9E75", amber: "#EF9F27",
  coral: "#D85A30", blue: "#378ADD", gray: "#888780",
};

export function Sidebar() {
  const pathname = usePathname();

  const isActive = (href: string) => {
    if (href === "/") return pathname === "/";
    return pathname.startsWith(href);
  };

  return (
    <aside className="fixed left-0 top-0 bottom-0 w-60 bg-[#0a0a0a] border-r border-[#222222] flex flex-col z-50">
      {/* Logo */}
      <div className="px-5 py-5 border-b border-[#222222]">
        <h1 className="text-base font-bold tracking-widest text-white">
          AETHRIUM
        </h1>
        <p className="text-[10px] text-[#888780] uppercase tracking-[0.2em] mt-0.5">
          OTServ Studio
        </p>
      </div>

      {/* Navigation */}
      <nav className="flex-1 overflow-y-auto py-3 px-3">
        <ul className="space-y-0.5">
          {navItems.map((item) => {
            const Icon = item.icon;
            const active = isActive(item.href);
            return (
              <li key={item.href}>
                <Link
                  href={item.href}
                  className={cn(
                    "flex items-center gap-3 px-3 py-2 rounded-md text-sm transition-colors",
                    active
                      ? "bg-[#1a1a1a] text-white"
                      : "text-[#888780] hover:text-white hover:bg-[#1a1a1a]/50"
                  )}
                >
                  <Icon className="w-4 h-4 shrink-0" />
                  <span>{item.label}</span>
                  {active && (
                    <div className="ml-auto w-1.5 h-1.5 rounded-full bg-[#7F77DD]" />
                  )}
                </Link>
              </li>
            );
          })}
        </ul>
      </nav>
    </aside>
  );
}
