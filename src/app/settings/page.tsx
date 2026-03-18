"use client";

import { useState, useEffect } from "react";
import { 
  Settings, 
  Bot, 
  Key, 
  Server, 
  Info, 
  Save, 
  CheckCircle2, 
  XCircle, 
  Loader2,
  RefreshCw,
  Globe,
  Database,
  Cpu,
  Monitor
} from "lucide-react";
import { backendApi } from "@/lib/api";

const MODELS = [
  "gemini-1.5-flash-lite-preview-0930",
  "gemini-1.5-flash",
  "gemini-1.5-pro"
];

// Map user values to actual model strings if needed, but the prompt says:
// gemini-3.1-flash-lite-preview, gemini-2.5-flash, gemini-2.0-flash
// Since these are future/placeholder names, I will use them as requested.
const DISPLAY_MODELS = [
  "gemini-3.1-flash-lite-preview",
  "gemini-2.5-flash",
  "gemini-2.0-flash"
];

export default function SettingsPage() {
  const [agents, setAgents] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState<string | null>(null);
  const [status, setStatus] = useState<any>(null);
  const [backendUrl, setBackendUrl] = useState("");
  const [isProduction, setIsProduction] = useState(false);

  useEffect(() => {
    fetchData();
    setBackendUrl(process.env.NEXT_PUBLIC_BACKEND_URL || "http://localhost:8001");
    setIsProduction(window.location.hostname !== "localhost");
  }, []);

  const fetchData = async () => {
    try {
      const [agentsData, healthData] = await Promise.all([
        backendApi.getAgents(),
        fetch(`${process.env.NEXT_PUBLIC_BACKEND_URL || "http://localhost:8001"}/health`).then(r => r.json()).catch(() => ({ status: "offline" }))
      ]);
      setAgents(agentsData);
      setStatus(healthData);
    } catch (error) {
      console.error("Error fetching settings data:", error);
    } finally {
      setLoading(false);
    }
  };

  const handleUpdateModel = async (slug: string, newModel: string) => {
    setSaving(slug);
    try {
      await backendApi.updateAgentModel(slug, newModel);
      // Update local state
      setAgents(agents.map(a => a.slug === slug ? { ...a, model: newModel } : a));
    } catch (error) {
      console.error(`Failed to update model for ${slug}:`, error);
    } finally {
      setSaving(null);
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-[400px]">
        <Loader2 className="w-8 h-8 animate-spin text-purple-500" />
      </div>
    );
  }

  return (
    <div className="p-8 space-y-8 max-w-6xl mx-auto">
      <div className="flex items-center gap-3 border-b border-white/10 pb-6">
        <div className="p-3 bg-purple-500/20 rounded-xl border border-purple-500/30 text-purple-400">
          <Settings size={24} />
        </div>
        <div>
          <h1 className="text-3xl font-bold tracking-tight text-white">Configurações</h1>
          <p className="text-zinc-400">Gerencie a infraestrutura, modelos de IA e chaves de API do Hub.</p>
        </div>
      </div>

      {/* 1. SEÇÃO DE MODELOS DOS AGENTES */}
      <section className="space-y-4">
        <div className="flex items-center gap-2 text-white font-medium">
          <Bot size={20} className="text-blue-400" />
          <h2>Modelos dos Agentes</h2>
        </div>
        <div className="bg-black/40 border border-white/10 rounded-2xl overflow-hidden backdrop-blur-sm shadow-xl">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-white/5 text-zinc-400 text-xs font-semibold uppercase tracking-wider">
                <th className="px-6 py-4">Agente</th>
                <th className="px-6 py-4">Papel</th>
                <th className="px-6 py-4">Modelo Atual</th>
                <th className="px-6 py-4 text-right">Ação</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-white/10">
              {agents.map((agent) => (
                <tr key={agent.slug} className="group hover:bg-white/[0.02] transition-colors">
                  <td className="px-6 py-4 flex items-center gap-3">
                    <div className="w-10 h-10 rounded-lg bg-zinc-800 border border-white/10 flex items-center justify-center text-lg shadow-inner overflow-hidden">
                       {agent.avatar || "🤖"}
                    </div>
                    <div>
                      <div className="font-medium text-white">{agent.displayName || agent.name}</div>
                      <div className="text-xs text-zinc-500">{agent.slug}</div>
                    </div>
                  </td>
                  <td className="px-6 py-4">
                    <span className="text-sm text-zinc-300 bg-zinc-800/50 px-2 py-1 rounded-md border border-white/5">
                      {agent.role || "Especialista"}
                    </span>
                  </td>
                  <td className="px-6 py-4">
                    <select 
                      value={agent.model} 
                      onChange={(e) => handleUpdateModel(agent.slug, e.target.value)}
                      disabled={saving === agent.slug}
                      className="bg-zinc-900/50 border border-white/20 text-white text-sm rounded-lg focus:ring-purple-500 focus:border-purple-500 block w-full p-2 hover:border-white/40 transition-all outline-none"
                    >
                      {DISPLAY_MODELS.map(m => (
                        <option key={m} value={m}>{m}</option>
                      ))}
                    </select>
                  </td>
                  <td className="px-6 py-4 text-right">
                    {saving === agent.slug ? (
                      <Loader2 className="w-5 h-5 animate-spin text-purple-400 ml-auto" />
                    ) : (
                      <button className="text-zinc-500 hover:text-purple-400 transition-colors">
                        <Save size={18} />
                      </button>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </section>

      {/* 2. SEÇÃO DE CHAVES DE API */}
      <section className="space-y-4">
        <div className="flex items-center gap-2 text-white font-medium">
          <Key size={20} className="text-yellow-400" />
          <h2>Chaves de API (Configuradas no Backend)</h2>
        </div>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {[
            { label: "Google AI", key: "GOOGLE_API_KEY", icon: Cpu },
            { label: "Pinecone", key: "PINECONE_API_KEY", icon: Database },
            { label: "E2B", key: "E2B_API_KEY", icon: Monitor },
            { label: "Discord", key: "DISCORD_WEBHOOK_URL", icon: Globe },
            { label: "n8n", key: "N8N_URL", icon: RefreshCw },
          ].map((item) => (
            <div key={item.key} className="p-4 bg-black/40 border border-white/10 rounded-xl flex items-center justify-between backdrop-blur-sm group hover:border-white/20 transition-all">
              <div className="flex items-center gap-3">
                <item.icon className="w-5 h-5 text-zinc-500" />
                <span className="text-zinc-300 font-medium">{item.label}</span>
              </div>
              <div className="flex items-center gap-2">
                <span className="text-zinc-600 text-xs">●●●●●●●●</span>
                <CheckCircle2 size={16} className="text-green-500/80" />
              </div>
            </div>
          ))}
        </div>
      </section>

      {/* 3. CONFIGURAÇÃO DO SERVIDOR */}
      <section className="space-y-4">
        <div className="flex items-center gap-2 text-white font-medium">
          <Server size={20} className="text-green-400" />
          <h2>Servidor e Ambiente</h2>
        </div>
        <div className="bg-black/40 border border-white/10 rounded-2xl p-6 space-y-6 backdrop-blur-sm">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
            <div className="space-y-2">
              <label className="text-xs font-bold uppercase text-zinc-500">URL do Backend</label>
              <div className="flex gap-2">
                <input 
                  type="text" 
                  value={backendUrl}
                  readOnly
                  className="bg-zinc-900/50 border border-white/10 text-white rounded-lg p-2 flex-1 font-mono text-sm opacity-60 cursor-not-allowed"
                />
              </div>
            </div>
            <div className="space-y-2">
              <label className="text-xs font-bold uppercase text-zinc-500">Ambiente Atual</label>
              <div className="flex items-center gap-3">
                <div className={`px-4 py-2 rounded-lg border flex items-center gap-2 font-medium transition-all ${isProduction ? 'bg-orange-500/10 border-orange-500/40 text-orange-400 shadow-[0_0_15px_-3px_rgba(249,115,22,0.3)]' : 'bg-blue-500/10 border-blue-500/40 text-blue-400 shadow-[0_0_15px_-3px_rgba(59,130,246,0.3)]'}`}>
                  {isProduction ? <Monitor size={18} /> : <Cpu size={18} />}
                  {isProduction ? "Produção" : "Desenvolvimento"}
                </div>
                <div className="flex-1 h-px bg-white/10" />
                <span className={`flex items-center gap-1.5 text-xs ${status?.status === "ok" ? "text-green-400" : "text-red-400"}`}>
                  <div className={`w-2 h-2 rounded-full ${status?.status === "ok" ? "bg-green-400 animate-pulse" : "bg-red-400"}`} />
                  API {status?.status === "ok" ? "Online" : "Offline"}
                </span>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* 4. SOBRE */}
      <section className="space-y-4">
        <div className="flex items-center gap-2 text-white font-medium">
          <Info size={20} className="text-purple-400" />
          <h2>Sobre o Aethrium Hub</h2>
        </div>
        <div className="bg-zinc-900/40 border border-white/5 rounded-2xl p-6 text-zinc-400 text-sm leading-relaxed">
          <div className="flex flex-col md:flex-row gap-8 justify-between">
            <div className="space-y-2">
              <p><strong>Versão:</strong> 1.0.0 (Semana 8 Build)</p>
              <p><strong>Stack:</strong> Next.js 16, FastAPI, LangGraph, Supabase, Pinecone</p>
              <p><strong>Infra:</strong> Vercel (Frontend), Render (Backend)</p>
            </div>
            <div className="flex items-center gap-1">
              <span className="text-zinc-600 italic">Antigravity Design Engine &copy; 2026</span>
            </div>
          </div>
        </div>
      </section>
    </div>
  );
}
