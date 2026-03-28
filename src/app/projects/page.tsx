"use client";

import { useEffect, useState } from "react";
import { backendApi } from "@/lib/api";
import { FolderOpen, Cpu, Code2, Circle } from "lucide-react";

interface Project {
  id: string;
  slug: string;
  displayName: string;
  gameType: string;
  division: string;
  engine: string;
  language: string;
  isActive: boolean;
  metadata?: Record<string, unknown>;
  createdAt: string;
}

const GAME_TYPE_LABELS: Record<string, string> = {
  OTSERV: "OTServ",
  CANARY_MMORPG: "Canary MMORPG",
  CS2: "Counter-Strike 2",
  LINEAGE2: "Lineage II",
  MU_ONLINE: "MU Online",
  RAGNAROK: "Ragnarok Online",
  HAXBALL: "HaxBall",
};

const GAME_TYPE_COLORS: Record<string, string> = {
  OTSERV: "#7F77DD",
  CANARY_MMORPG: "#9B59B6",
  CS2: "#F4A01C",
  LINEAGE2: "#E74C3C",
  MU_ONLINE: "#1ABC9C",
  RAGNAROK: "#3498DB",
  HAXBALL: "#2ECC71",
};

function ProjectCard({ project }: { project: Project }) {
  const color = GAME_TYPE_COLORS[project.gameType] ?? "#888780";
  const label = GAME_TYPE_LABELS[project.gameType] ?? project.gameType;

  return (
    <div className="bg-[#111111] border border-[#222222] rounded-lg p-4 flex flex-col gap-3 hover:border-[#333333] transition-colors">
      <div className="flex items-start justify-between gap-2">
        <div className="flex items-center gap-2">
          <div className="w-2 h-2 rounded-full mt-1" style={{ backgroundColor: color }} />
          <h3 className="text-sm font-semibold text-white leading-tight">{project.displayName}</h3>
        </div>
        <span
          className="text-[10px] px-2 py-0.5 rounded-full font-medium shrink-0"
          style={{ backgroundColor: `${color}22`, color }}
        >
          {label}
        </span>
      </div>

      <div className="flex flex-col gap-1.5 text-xs text-[#888780]">
        <div className="flex items-center gap-1.5">
          <Cpu className="w-3 h-3 shrink-0" />
          <span>{project.engine}</span>
        </div>
        <div className="flex items-center gap-1.5">
          <Code2 className="w-3 h-3 shrink-0" />
          <span>{project.language}</span>
        </div>
      </div>

      <div className="flex items-center justify-between pt-1 border-t border-[#1a1a1a]">
        <span className="text-[10px] text-[#555555] font-mono">{project.slug}</span>
        <div className="flex items-center gap-1">
          <Circle
            className="w-2 h-2"
            fill={project.isActive ? "#1D9E75" : "#555555"}
            stroke="none"
          />
          <span className={`text-[10px] ${project.isActive ? "text-[#1D9E75]" : "text-[#555555]"}`}>
            {project.isActive ? "Ativo" : "Provisionando"}
          </span>
        </div>
      </div>
    </div>
  );
}

export default function ProjectsPage() {
  const [studioProjects, setStudioProjects] = useState<Project[]>([]);
  const [publisherProjects, setPublisherProjects] = useState<Project[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function load() {
      try {
        const [studio, publisher] = await Promise.all([
          fetch(`${process.env.NEXT_PUBLIC_BACKEND_URL}/projects?division=STUDIO`).then(r => r.json()),
          fetch(`${process.env.NEXT_PUBLIC_BACKEND_URL}/projects?division=PUBLISHER`).then(r => r.json()),
        ]);
        setStudioProjects(Array.isArray(studio) ? studio : []);
        setPublisherProjects(Array.isArray(publisher) ? publisher : []);
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
        <div className="text-[#555555] text-sm">Carregando projetos...</div>
      </div>
    );
  }

  return (
    <div className="space-y-8">
      <div>
        <h1 className="text-xl font-bold text-white tracking-tight flex items-center gap-2">
          <FolderOpen className="w-5 h-5 text-[#7F77DD]" />
          Projetos
        </h1>
        <p className="text-sm text-[#555555] mt-1">Todos os projetos do Aethrium Hub — Studio e Publisher</p>
      </div>

      {/* Studio */}
      <section>
        <div className="flex items-center gap-2 mb-3">
          <h2 className="text-sm font-semibold text-[#888780] uppercase tracking-widest">Studio</h2>
          <div className="flex-1 h-px bg-[#1a1a1a]" />
          <span className="text-xs text-[#555555]">{studioProjects.length} projetos</span>
        </div>
        {studioProjects.length === 0 ? (
          <p className="text-xs text-[#555555] py-4">Nenhum projeto de Studio encontrado.</p>
        ) : (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3">
            {studioProjects.map(p => <ProjectCard key={p.id} project={p} />)}
          </div>
        )}
      </section>

      {/* Publisher */}
      <section>
        <div className="flex items-center gap-2 mb-3">
          <h2 className="text-sm font-semibold text-[#888780] uppercase tracking-widest">Publisher</h2>
          <div className="flex-1 h-px bg-[#1a1a1a]" />
          <span className="text-xs text-[#555555]">{publisherProjects.length} servidores</span>
        </div>
        {publisherProjects.length === 0 ? (
          <p className="text-xs text-[#555555] py-4">Nenhum servidor Publisher encontrado.</p>
        ) : (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3">
            {publisherProjects.map(p => <ProjectCard key={p.id} project={p} />)}
          </div>
        )}
      </section>
    </div>
  );
}
