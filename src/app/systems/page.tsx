'use client'

import { useState, useEffect } from 'react';
import { SectionHeader } from "@/components/section-header";
import { StatusBadge } from "@/components/status-badge";
import Link from "next/link";
import { ExternalLink, Database, RefreshCcw, Trash2, Search, Play, FileText, CheckCircle2, Loader2, X } from "lucide-react";
import { backendApi } from '@/lib/api';

interface SystemCard {
  name: string;
  description: string;
  status: "implemented" | "pending";
  revenue: string;
  agent: string;
  progress: number;
  tag: string;
}

const systems: SystemCard[] = [
  {
    name: "Dodge / Critical / Reflect",
    description: "Gacha system for combat enhancement stones with weighted random drops",
    status: "implemented",
    revenue: "R$300–3.000/mês",
    agent: "Thiago",
    progress: 100,
    tag: "dodge-stones",
  },
  {
    name: "VIP System",
    description: "3-tier VIP (Bronze R$15, Prata R$25, Ouro R$40) with exclusive perks",
    status: "implemented",
    revenue: "R$190–1.875/mês",
    agent: "Rafael",
    progress: 100,
    tag: "vip",
  },
  {
    name: "Stamina Refill",
    description: "4 refill plans (3h R$10, 42h R$25, Infinite 7d R$50) for hunting stamina",
    status: "implemented",
    revenue: "R$250–1.800/mês",
    agent: "Rafael",
    progress: 100,
    tag: "stamina",
  },
  {
    name: "Reset System",
    description: "Character reset at level 1000, preserving skill points and unlocking cosmetics",
    status: "pending",
    revenue: "Indirect — retention",
    agent: "Thiago",
    progress: 25,
    tag: "reset",
  },
  {
    name: "Guild Points",
    description: "Guild ranking system with weekly rewards based on accumulated points",
    status: "pending",
    revenue: "Indirect — engagement",
    agent: "Viktor",
    progress: 10,
    tag: "guild-points",
  },
  {
    name: "Mining / Refinement",
    description: "Resource gathering and weapon upgrade crafting system",
    status: "pending",
    revenue: "R$100–800/mês",
    agent: "Beatriz",
    progress: 5,
    tag: "mining",
  },
];

const statusColors: Record<string, string> = {
  implemented: "#1D9E75",
  pending: "#EF9F27",
};

export default function SystemsPage() {
  const [projectStatus, setProjectStatus] = useState<{chunks_indexed: number} | null>(null);
  const [isIndexing, setIsIndexing] = useState(false);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [projectPath, setProjectPath] = useState("/app/projects/baiak-thunder-86");
  const [query, setQuery] = useState("");
  const [queryResults, setQueryResults] = useState<any[]>([]);
  const [isSearching, setIsSearching] = useState(false);

  const fetchStatus = async () => {
    try {
      const data = await backendApi.getProjectStatus("baiak-thunder-86");
      setProjectStatus(data);
    } catch (err) {
      console.error("Failed to fetch status", err);
    }
  };

  useEffect(() => {
    fetchStatus();
    const interval = setInterval(fetchStatus, 5000);
    return () => clearInterval(interval);
  }, []);

  const handleIndex = async () => {
    try {
      setIsIndexing(true);
      await backendApi.indexProject('baiak-thunder-86', projectPath);
      alert('Indexação iniciada em segundo plano!');
    } catch (err) {
      alert('Erro ao iniciar indexação');
    } finally {
      setIsIndexing(false);
    }
  };

  const handleDeleteIndex = async () => {
    if (!confirm("Tem certeza que deseja remover o índice RAG deste projeto?")) return;
    try {
      await backendApi.deleteProjectIndex("baiak-thunder-86");
      fetchStatus();
    } catch (err) {
      console.error(err);
    }
  };

  const handleSearch = async () => {
    if (!query.trim()) return;
    setIsSearching(true);
    try {
      const data = await backendApi.queryRAG(query, "baiak-thunder-86");
      setQueryResults(data.results || []);
    } catch (err) {
      console.error(err);
    } finally {
      setIsSearching(false);
    }
  };

  return (
    <div className="space-y-12 pb-20">
      <SectionHeader title="Systems" subtitle="Monetization and gameplay systems" />

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        {systems.map((sys) => (
          <div
            key={sys.tag}
            className="bg-[#111111] border border-[#222222] rounded-lg p-5 hover:border-[#333333] transition-colors"
            style={{ borderLeft: `3px solid ${statusColors[sys.status]}` }}
          >
            <div className="flex items-start justify-between mb-2">
              <h3 className="text-sm font-semibold text-white">{sys.name}</h3>
              <StatusBadge variant={sys.status} />
            </div>
            <p className="text-xs text-[#888780] mb-3 leading-relaxed">{sys.description}</p>

            <div className="flex items-center gap-4 text-xs text-[#888780] mb-3">
              <span>
                Revenue: <span className="text-[#EF9F27] font-medium">{sys.revenue}</span>
              </span>
              <span>
                Agent: <span className="text-white">{sys.agent}</span>
              </span>
            </div>

            <div className="mb-3">
              <div className="flex items-center justify-between text-[10px] text-[#888780] mb-1">
                <span>Progress</span>
                <span>{sys.progress}%</span>
              </div>
              <div className="w-full h-1.5 bg-[#1a1a1a] rounded-full overflow-hidden">
                <div
                  className="h-full rounded-full transition-all"
                  style={{
                    width: `${sys.progress}%`,
                    backgroundColor: statusColors[sys.status],
                  }}
                />
              </div>
            </div>

            <Link
              href={`/tasks?system=${sys.tag}`}
              className="inline-flex items-center gap-1 text-xs text-[#888780] hover:text-white transition-colors"
            >
              View tasks <ExternalLink className="w-3 h-3" />
            </Link>
          </div>
        ))}
      </div>

      {/* RAG & Project Section */}
      <div className="mt-16 pt-8 border-t border-[#222]">
        <SectionHeader title="Project Onboarding" subtitle="Knowledge Base & RAG Management" />
        
        <div className="grid grid-cols-1 xl:grid-cols-3 gap-6 mt-6">
          {/* Project Card */}
          <div className="xl:col-span-2 bg-[#0d0d0d] border border-[#222] rounded-xl overflow-hidden flex flex-col">
            <div className="p-6 border-b border-[#222] bg-gradient-to-r from-purple-500/5 to-transparent flex items-center justify-between">
              <div className="flex items-center gap-4">
                <div className="w-12 h-12 rounded-lg bg-[#1a1a1a] border border-[#333] flex items-center justify-center shadow-lg">
                  <Database className="text-purple-400 w-6 h-6" />
                </div>
                <div>
                  <h3 className="text-sm font-bold text-white uppercase tracking-tight">Baiak Thunder 8.6</h3>
                  <div className="flex items-center gap-2 mt-1">
                    <span className="text-[10px] px-1.5 py-0.5 rounded bg-purple-500/10 text-purple-400 font-mono border border-purple-500/20">baiak-thunder-86</span>
                    {projectStatus?.chunks_indexed ? (
                      <span className="flex items-center gap-1 text-[10px] text-emerald-400">
                        <CheckCircle2 size={10} /> Indexado
                      </span>
                    ) : (
                      <span className="text-[10px] text-gray-500 italic">Não indexado</span>
                    )}
                  </div>
                </div>
              </div>

              <div className="flex items-center gap-2">
                 <button 
                  onClick={() => setIsModalOpen(true)}
                  className="px-3 py-1.5 bg-[#1a1a1a] border border-[#333] hover:bg-[#222] text-[#eee] rounded-md text-[11px] font-bold transition-all flex items-center gap-2"
                 >
                   <Play size={12} className="text-purple-400" /> {projectStatus?.chunks_indexed ? "Re-indexar" : "Indexar Projeto"}
                 </button>
                 {projectStatus && projectStatus.chunks_indexed > 0 && (
                   <button 
                    onClick={handleDeleteIndex}
                    className="p-1.5 hover:bg-red-500/10 text-[#444] hover:text-red-400 rounded-md transition-all"
                   >
                     <Trash2 size={14} />
                   </button>
                 )}
              </div>
            </div>

            <div className="p-6 grid grid-cols-3 gap-4 bg-[#0a0a0a]/50">
              <div className="p-4 rounded-lg bg-[#111] border border-[#222] flex flex-col gap-1">
                <span className="text-[10px] text-[#555] font-bold uppercase tracking-widest">Knowledge Chunks</span>
                <span className="text-xl font-mono text-white tabular-nums">{projectStatus?.chunks_indexed || 0}</span>
              </div>
              <div className="p-4 rounded-lg bg-[#111] border border-[#222] flex flex-col gap-1">
                <span className="text-[10px] text-[#555] font-bold uppercase tracking-widest">Last Index</span>
                <span className="text-[11px] text-[#888] font-mono mt-1">{projectStatus?.chunks_indexed ? "—" : "Nunca"}</span>
              </div>
              <div className="p-4 rounded-lg bg-[#111] border border-[#222] flex flex-col gap-1">
                <span className="text-[10px] text-[#555] font-bold uppercase tracking-widest">Vector Store</span>
                <span className="text-[11px] text-emerald-500 font-bold mt-1">Pinecone Active</span>
              </div>
            </div>

            {/* RAG Tester */}
            <div className="flex-1 p-6 bg-[#0a0a0a] space-y-4">
              <div className="flex items-center justify-between">
                <h4 className="text-[10px] font-bold text-gray-500 uppercase tracking-widest flex items-center gap-2">
                  <Search size={12} /> Testar Consulta RAG
                </h4>
              </div>
              
              <div className="relative group">
                <input 
                  type="text"
                  placeholder="Ex: Como funciona o sistema de VIP?"
                  value={query}
                  onChange={e => setQuery(e.target.value)}
                  onKeyDown={e => e.key === 'Enter' && handleSearch()}
                  className="w-full bg-[#111] border border-[#222] group-hover:border-[#333] focus:border-purple-500 rounded-lg pl-4 pr-12 py-3 text-sm text-white focus:outline-none transition-all placeholder:text-[#333]"
                />
                <button 
                  onClick={handleSearch}
                  disabled={isSearching}
                  className="absolute right-2 top-1/2 -translate-y-1/2 p-2 bg-purple-600 hover:bg-purple-700 text-white rounded-md transition-all shadow-lg"
                >
                  {isSearching ? <Loader2 size={16} className="animate-spin" /> : <RefreshCcw size={16} />}
                </button>
              </div>

              {queryResults.length > 0 && (
                <div className="space-y-3 mt-4 animate-in fade-in slide-in-from-top-2">
                   {queryResults.map((res, i) => (
                     <div key={i} className="bg-[#111] border border-[#222] rounded-lg p-3 hover:border-purple-500/30 transition-all group">
                       <div className="flex items-center justify-between mb-2">
                         <div className="flex items-center gap-2">
                           <FileText size={12} className="text-[#444]" />
                           <span className="text-[10px] font-mono text-purple-400 truncate max-w-[200px]">{res.source}</span>
                         </div>
                         <span className="text-[9px] font-mono text-[#333]">Score: {res.score.toFixed(4)}</span>
                       </div>
                       <p className="text-[11px] text-[#777] leading-relaxed line-clamp-2 italic group-hover:text-[#aaa]">"{res.text}"</p>
                     </div>
                   ))}
                </div>
              )}
            </div>
          </div>

          {/* Quick Stats / Legend */}
          <div className="bg-[#0d0d0d] border border-[#222] rounded-xl p-6 space-y-6">
            <h3 className="text-[10px] font-bold text-[#555] uppercase tracking-[0.2em]">Context Mapping</h3>
            
            <div className="space-y-4">
              <div className="flex items-center gap-3">
                <div className="w-1.5 h-6 bg-teal-500 rounded-full" />
                <div>
                  <div className="text-[11px] font-bold text-[#eee]">Scripts Lua (.lua)</div>
                  <div className="text-[9px] text-[#444]">Atribuído ao agente: <span className="text-teal-400">Rafael</span></div>
                </div>
              </div>
              <div className="flex items-center gap-3">
                <div className="w-1.5 h-6 bg-blue-500 rounded-full" />
                <div>
                  <div className="text-[11px] font-bold text-[#eee]">Engine C++ (.cpp, .h)</div>
                  <div className="text-[9px] text-[#444]">Atribuído ao agente: <span className="text-blue-400">Viktor</span></div>
                </div>
              </div>
              <div className="flex items-center gap-3">
                <div className="w-1.5 h-6 bg-amber-500 rounded-full" />
                <div>
                  <div className="text-[11px] font-bold text-[#eee]">Configurações (.xml, .json)</div>
                  <div className="text-[9px] text-[#444]">Atribuído ao agente: <span className="text-purple-400">Carlos / Rafael</span></div>
                </div>
              </div>
            </div>

            <div className="pt-6 border-t border-[#222]">
              <div className="bg-purple-500/5 rounded-lg p-4 border border-purple-500/10">
                <h4 className="text-[11px] font-bold text-purple-400 mb-1">Dica RAG</h4>
                <p className="text-[11px] text-[#666] leading-relaxed">
                  O sistema divide arquivos em pedaços de 1500 caracteres para garantir que os agentes recebam apenas o contexto relevante, economizando tokens e melhorando a precisão.
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Index Modal */}
      {isModalOpen && (
        <div className="fixed inset-0 z-[60] flex items-center justify-center p-4 bg-black/80 backdrop-blur-sm animate-in fade-in">
          <div className="bg-[#111] border border-[#222] rounded-xl w-full max-w-lg shadow-2xl overflow-hidden">
            <div className="p-6 border-b border-[#222] flex items-center justify-between">
               <h3 className="text-sm font-bold text-white uppercase tracking-tight">Indexar Projeto</h3>
               <button onClick={() => setIsModalOpen(false)} className="text-[#444] hover:text-white transition-colors">
                 <X size={20} />
               </button>
            </div>
            
            <div className="p-6 space-y-4">
              <div className="space-y-2">
                <label className="text-[10px] font-bold text-[#555] uppercase">Slug do Projeto</label>
                <input 
                  disabled
                  value="baiak-thunder-86"
                  className="w-full bg-[#0a0a0a] border border-[#222] rounded-lg px-4 py-2 text-xs text-[#555] font-mono"
                />
              </div>

              <div className="space-y-2">
                <label className="text-[10px] font-bold text-[#555] uppercase">Caminho no Sistema</label>
                <input 
                  value={projectPath}
                  onChange={e => setProjectPath(e.target.value)}
                  className="w-full bg-[#0d0d0d] border border-[#333] focus:border-purple-500 rounded-lg px-4 py-2 text-xs text-[#eee] focus:outline-none focus:ring-1 focus:ring-purple-500/50"
                  placeholder="C:/caminho/do/projeto"
                />
              </div>

              <div className="pt-4">
                <button 
                  onClick={handleIndex}
                  disabled={isIndexing}
                  className="w-full bg-purple-600 hover:bg-purple-700 disabled:bg-[#1a1a1a] text-white rounded-lg py-3 text-sm font-bold transition-all shadow-xl shadow-purple-500/10 flex items-center justify-center gap-2"
                >
                  {isIndexing ? (
                    <>
                      <Loader2 size={16} className="animate-spin" /> Indexando arquivos...
                    </>
                  ) : (
                    "Confirmar e Iniciar Indexação →"
                  )}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

