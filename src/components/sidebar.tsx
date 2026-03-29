"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { useEffect, useState, useRef } from "react";
import { cn } from "@/lib/utils";
import {
  LayoutDashboard, Bot, ListTodo, DollarSign, Users, Cpu,
  Map, ScrollText, Settings, Zap, FolderOpen, Server,
  ChevronDown, Check, Menu, X
} from "lucide-react";
import { backendApi } from "@/lib/api";
import { useProjectStore, ActiveProject } from "@/store/useProjectStore";

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
  DESIGNER: "Designer",
  LORE_WRITER: "Lore Writer",
};

const GAME_TYPE_COLORS: Record<string, string> = {
  OTSERV:        "#7F77DD",
  CANARY_MMORPG: "#9B59B6",
  CS2:           "#F4A01C",
  LINEAGE2:      "#E74C3C",
  MU_ONLINE:     "#1ABC9C",
  RAGNAROK:      "#3498DB",
  HAXBALL:       "#2ECC71",
};

const navItems = [
  { href: "/", label: "Overview", icon: LayoutDashboard },
  { href: "/agents", label: "Agents", icon: Bot },
  { href: "/tasks", label: "Tasks", icon: ListTodo },
  { href: "/projects", label: "Projects", icon: FolderOpen },
  { href: "/knowledge-base", label: "Knowledge Base", icon: Cpu },
  { href: "/logs", label: "Logs", icon: ScrollText },
  { href: "/integrations", label: "Integrations", icon: Zap },
  { href: "/settings", label: "Settings", icon: Settings },
];

// ── Active Project Selector ───────────────────────────────────────────────────

function ProjectSelector() {
  const { activeProject, projects, setActiveProject, setProjects } = useProjectStore();
  const [open, setOpen] = useState(false);
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const backendUrl = process.env.NEXT_PUBLIC_BACKEND_URL;
    if (!backendUrl) return;
    fetch(`${backendUrl}/projects?division=STUDIO`)
      .then(r => r.json())
      .then((data: ActiveProject[]) => {
        if (!Array.isArray(data) || data.length === 0) return;
        setProjects(data);
        // Auto-select baiak-thunder-86 if nothing is persisted yet
        if (!activeProject) {
          const baiak = data.find(p => p.slug === 'baiak-thunder-86') ?? data[0];
          setActiveProject(baiak);
        }
      })
      .catch(() => {});
  }, []); // eslint-disable-line react-hooks/exhaustive-deps

  // Close on outside click
  useEffect(() => {
    const handler = (e: MouseEvent) => {
      if (ref.current && !ref.current.contains(e.target as Node)) setOpen(false);
    };
    document.addEventListener('mousedown', handler);
    return () => document.removeEventListener('mousedown', handler);
  }, []);

  const color = activeProject ? (GAME_TYPE_COLORS[activeProject.gameType] ?? '#888780') : '#555555';
  const label = activeProject?.displayName ?? 'Selecionar projeto...';

  return (
    <div ref={ref} className="relative px-3 py-2.5 border-b border-[#1a1a1a]">
      <p className="text-[9px] text-[#444] uppercase tracking-[0.2em] mb-1.5 font-medium">
        Projeto Ativo
      </p>
      <button
        onClick={() => setOpen(o => !o)}
        className="w-full flex items-center gap-2 px-2.5 py-1.5 rounded-md bg-[#111] border border-[#222] hover:border-[#333] transition-colors text-left"
      >
        <div className="w-2 h-2 rounded-full shrink-0" style={{ backgroundColor: color }} />
        <span className="text-[11px] text-white flex-1 truncate font-medium">{label}</span>
        <ChevronDown
          className={cn("w-3 h-3 text-[#555] shrink-0 transition-transform", open && "rotate-180")}
        />
      </button>

      {open && projects.length > 0 && (
        <div className="absolute left-3 right-3 top-full mt-1 bg-[#111] border border-[#222] rounded-md shadow-xl z-50 overflow-hidden">
          {projects.map(p => {
            const pColor = GAME_TYPE_COLORS[p.gameType] ?? '#888780';
            const isSelected = activeProject?.slug === p.slug;
            return (
              <button
                key={p.slug}
                onClick={() => { setActiveProject(p); setOpen(false); }}
                className={cn(
                  "w-full flex items-center gap-2 px-3 py-2 text-left transition-colors text-[11px]",
                  isSelected
                    ? "bg-[#1a1a1a] text-white"
                    : "text-[#888] hover:bg-[#161616] hover:text-white"
                )}
              >
                <div className="w-1.5 h-1.5 rounded-full shrink-0" style={{ backgroundColor: pColor }} />
                <span className="flex-1 truncate">{p.displayName}</span>
                {isSelected && <Check className="w-3 h-3 text-[#7F77DD] shrink-0" />}
              </button>
            );
          })}
        </div>
      )}
    </div>
  );
}

// ── Sidebar ───────────────────────────────────────────────────────────────────

export function Sidebar() {
  const pathname = usePathname();
  const [mobileOpen, setMobileOpen] = useState(false);

  const isActive = (href: string) => {
    if (href === "/") return pathname === "/";
    return pathname.startsWith(href);
  };

  const navContent = (
    <>
      {/* Logo */}
      <div className="px-5 py-5 border-b border-[#222222] flex items-center justify-between">
        <div>
          <h1 className="text-base font-bold tracking-widest text-white">AETHRIUM</h1>
          <p className="text-[10px] text-[#888780] uppercase tracking-[0.2em] mt-0.5">Game Studio</p>
        </div>
        <button
          onClick={() => setMobileOpen(false)}
          className="md:hidden p-1 rounded text-[#888780] hover:text-white"
        >
          <X className="w-4 h-4" />
        </button>
      </div>

      {/* Active Project Selector */}
      <ProjectSelector />

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
                  onClick={() => setMobileOpen(false)}
                  className={cn(
                    "flex items-center gap-3 px-3 py-2 rounded-md text-sm transition-colors",
                    active
                      ? "bg-[#1a1a1a] text-white"
                      : "text-[#888780] hover:text-white hover:bg-[#1a1a1a]/50"
                  )}
                >
                  <Icon className="w-4 h-4 shrink-0" />
                  <span>{item.label}</span>
                  {active && <div className="ml-auto w-1.5 h-1.5 rounded-full bg-[#7F77DD]" />}
                </Link>
              </li>
            );
          })}
        </ul>
      </nav>
    </>
  );

  return (
    <>
      {/* Mobile top bar */}
      <div className="md:hidden fixed top-0 left-0 right-0 h-14 bg-[#0a0a0a] border-b border-[#222222] flex items-center px-4 z-40">
        <button
          onClick={() => setMobileOpen(true)}
          className="p-2 rounded text-[#888780] hover:text-white hover:bg-[#1a1a1a] transition-colors"
        >
          <Menu className="w-5 h-5" />
        </button>
        <span className="ml-3 text-sm font-bold tracking-widest text-white">AETHRIUM</span>
      </div>

      {/* Mobile backdrop */}
      {mobileOpen && (
        <div
          className="md:hidden fixed inset-0 bg-black/60 z-40"
          onClick={() => setMobileOpen(false)}
        />
      )}

      {/* Sidebar — desktop: fixed; mobile: drawer */}
      <aside className={cn(
        "fixed left-0 top-0 bottom-0 w-60 bg-[#0a0a0a] border-r border-[#222222] flex flex-col z-50 transition-transform duration-300",
        "md:translate-x-0",
        mobileOpen ? "translate-x-0" : "-translate-x-full md:translate-x-0"
      )}>
        {navContent}
      </aside>
    </>
  );
}
