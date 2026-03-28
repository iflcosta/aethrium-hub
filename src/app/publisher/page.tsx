"use client";

import { useEffect, useState } from "react";
import { Server, Circle, Cpu, Code2, ExternalLink } from "lucide-react";

interface Project {
  id: string;
  slug: string;
  displayName: string;
  gameType: string;
  division: string;
  engine: string;
  language: string;
  isActive: boolean;
  metadata?: {
    status?: string;
    description?: string;
    max_players?: number;
    season?: number;
    chronicle?: string;
    tickrate?: number;
    [key: string]: unknown;
  };
}

const GAME_ICONS: Record<string, string> = {
  CS2: "🎯",
  LINEAGE2: "⚔️",
  MU_ONLINE: "🔮",
  RAGNAROK: "🌊",
  HAXBALL: "⚽",
};

const GAME_TYPE_COLORS: Record<string, string> = {
  CS2: "#F4A01C",
  LINEAGE2: "#E74C3C",
  MU_ONLINE: "#1ABC9C",
  RAGNAROK: "#3498DB",
  HAXBALL: "#2ECC71",
};

const GAME_TYPE_LABELS: Record<string, string> = {
  CS2: "Counter-Strike 2",
  LINEAGE2: "Lineage II",
  MU_ONLINE: "MU Online",
  RAGNAROK: "Ragnarok Online",
  HAXBALL: "HaxBall",
};

function ServerCard({ project }: { project: Project }) {
  const color = GAME_TYPE_COLORS[project.gameType] ?? "#888780";
  const icon = GAME_ICONS[project.gameType] ?? "🎮";
  const label = GAME_TYPE_LABELS[project.gameType] ?? project.gameType;
  const meta = project.metadata ?? {};

  return (
    <div className="bg-[#111111] border border-[#222222] rounded-lg p-5 flex flex-col gap-4 hover:border-[#333333] transition-colors">
      {/* Header */}
      <div className="flex items-start gap-3">
        <div
          className="w-10 h-10 rounded-lg flex items-center justify-center text-xl shrink-0"
          style={{ backgroundColor: `${color}18` }}
        >
          {icon}
        </div>
        <div className="flex-1 min-w-0">
          <h3 className="text-sm font-semibold text-white truncate">{project.displayName}</h3>
          <p className="text-xs text-[#555555] mt-0.5">{label}</p>
        </div>
        <div className="flex items-center gap-1.5 shrink-0">
          <Circle
            className="w-2 h-2"
            fill={project.isActive ? "#1D9E75" : "#555555"}
            stroke="none"
          />
          <span className={`text-[10px] font-medium ${project.isActive ? "text-[#1D9E75]" : "text-[#555555]"}`}>
            {project.isActive ? "Online" : "Offline"}
          </span>
        </div>
      </div>

      {/* Description */}
      {meta.description && (
        <p className="text-xs text-[#666666] leading-relaxed">{meta.description}</p>
      )}

      {/* Details */}
      <div className="grid grid-cols-2 gap-2">
        <div className="flex items-center gap-1.5 text-xs text-[#888780]">
          <Cpu className="w-3 h-3 shrink-0 text-[#555555]" />
          <span className="truncate">{project.engine}</span>
        </div>
        <div className="flex items-center gap-1.5 text-xs text-[#888780]">
          <Code2 className="w-3 h-3 shrink-0 text-[#555555]" />
          <span className="truncate">{project.language}</span>
        </div>
        {meta.max_players && (
          <div className="text-xs text-[#888780]">
            <span className="text-[#555555]">Max jogadores:</span>{" "}
            <span className="text-white">{meta.max_players}</span>
          </div>
        )}
        {meta.tickrate && (
          <div className="text-xs text-[#888780]">
            <span className="text-[#555555]">Tickrate:</span>{" "}
            <span className="text-white">{meta.tickrate}</span>
          </div>
        )}
        {meta.season && (
          <div className="text-xs text-[#888780]">
            <span className="text-[#555555]">Season:</span>{" "}
            <span className="text-white">{meta.season}</span>
          </div>
        )}
        {meta.chronicle && (
          <div className="text-xs text-[#888780]">
            <span className="text-[#555555]">Chronicle:</span>{" "}
            <span className="text-white">{meta.chronicle}</span>
          </div>
        )}
      </div>

      {/* Status */}
      <div className="pt-3 border-t border-[#1a1a1a] flex items-center justify-between">
        <span className="text-[10px] font-mono text-[#444444]">{project.slug}</span>
        <span
          className="text-[10px] px-2 py-0.5 rounded-full"
          style={{ backgroundColor: `${color}18`, color }}
        >
          {meta.status?.replace(/_/g, " ") ?? "desconhecido"}
        </span>
      </div>
    </div>
  );
}

export default function PublisherPage() {
  const [projects, setProjects] = useState<Project[]>([]);
  const [loading, setLoading] = useState(true);

  const onlineCount = projects.filter(p => p.isActive).length;
  const offlineCount = projects.filter(p => !p.isActive).length;

  useEffect(() => {
    async function load() {
      try {
        const data = await fetch(
          `${process.env.NEXT_PUBLIC_BACKEND_URL}/projects?division=PUBLISHER`
        ).then(r => r.json());
        setProjects(Array.isArray(data) ? data : []);
      } catch {
        // If backend is unavailable, show empty state
      } finally {
        setLoading(false);
      }
    }
    load();
  }, []);

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-[#555555] text-sm">Carregando servidores...</div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div>
        <h1 className="text-xl font-bold text-white tracking-tight flex items-center gap-2">
          <Server className="w-5 h-5 text-[#1D9E75]" />
          Publisher
        </h1>
        <p className="text-sm text-[#555555] mt-1">
          Servidores de jogos hospedados e operados pela Aethrium Hub
        </p>
      </div>

      {/* KPI Strip */}
      <div className="grid grid-cols-3 gap-3">
        <div className="bg-[#111111] border border-[#222222] rounded-lg p-4">
          <p className="text-xs text-[#555555] mb-1">Total de Servidores</p>
          <p className="text-2xl font-bold text-white">{projects.length}</p>
        </div>
        <div className="bg-[#111111] border border-[#222222] rounded-lg p-4">
          <p className="text-xs text-[#555555] mb-1">Online</p>
          <p className="text-2xl font-bold text-[#1D9E75]">{onlineCount}</p>
        </div>
        <div className="bg-[#111111] border border-[#222222] rounded-lg p-4">
          <p className="text-xs text-[#555555] mb-1">Offline / Setup</p>
          <p className="text-2xl font-bold text-[#555555]">{offlineCount}</p>
        </div>
      </div>

      {/* Server Grid */}
      {projects.length === 0 ? (
        <div className="text-center py-16 text-[#555555] text-sm">
          Nenhum servidor Publisher encontrado.
        </div>
      ) : (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
          {projects.map(p => (
            <ServerCard key={p.id} project={p} />
          ))}
        </div>
      )}
    </div>
  );
}
