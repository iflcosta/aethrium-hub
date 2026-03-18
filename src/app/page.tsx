"use client";

import { useEffect, useState } from "react";
import { KpiCard } from "@/components/kpi-card";
import { SectionHeader } from "@/components/section-header";
import { AgentAvatar } from "@/components/agent-avatar";
import { StatusBadge } from "@/components/status-badge";
import { backendApi, BACKEND_URL } from "@/lib/api";
import { 
  DollarSign, 
  Bot, 
  ListTodo, 
  Cpu, 
  Globe, 
  Server, 
  Database, 
  Cloud,
  CheckCircle2,
  AlertCircle,
  Loader2
} from "lucide-react";
import { mockTasks } from "@/lib/mock/tasks";
import { cn } from "@/lib/utils";

interface Agent {
  slug: string;
  displayName: string;
  model: string;
  role: string;
  color: string;
  isOnline: boolean;
  avatar?: string;
}

const StatusIndicator = ({ label, status, url, icon: Icon }: { label: string, status: 'healthy' | 'unreachable' | 'not-configured', url?: string, icon: any }) => (
  <div className="flex flex-col gap-2 p-3 rounded-xl bg-white/[0.03] border border-white/[0.05] hover:bg-white/[0.06] transition-all group">
    <div className="flex items-center justify-between">
      <div className="flex items-center gap-2">
        <div className={cn("p-1.5 rounded-lg", {
          "bg-green-500/10 text-green-400": status === 'healthy',
          "bg-red-500/10 text-red-400": status === 'unreachable',
          "bg-zinc-500/10 text-zinc-500": status === 'not-configured'
        })}>
          <Icon size={14} />
        </div>
        <span className="text-xs font-semibold text-zinc-200">{label}</span>
      </div>
      <div className={cn("w-1.5 h-1.5 rounded-full shadow-[0_0_10px_rgba(0,0,0,0.5)]", {
        "bg-green-400 shadow-green-400/50 animate-pulse": status === 'healthy',
        "bg-red-400 shadow-red-400/50": status === 'unreachable',
        "bg-zinc-600": status === 'not-configured'
      })} />
    </div>
    <div className="text-[10px] text-zinc-500 font-mono truncate group-hover:text-zinc-400 transition-colors">
      {url || "Not configured"}
    </div>
  </div>
);

export default function OverviewPage() {
  const [agents, setAgents] = useState<Agent[]>([]);
  const [health, setHealth] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchData = async () => {
      try {
        const [agentsRes, healthRes] = await Promise.all([
          backendApi.getAgents(),
          fetch(`${BACKEND_URL}/health`).then(r => r.json()).catch(() => ({ status: "offline" }))
        ]);
        setAgents(Array.isArray(agentsRes) ? agentsRes : []);
        setHealth(healthRes);
      } catch (error) {
        console.error("Overview fetch error:", error);
      } finally {
        setLoading(false);
      }
    };

    fetchData();
    const interval = setInterval(fetchData, 30000);
    return () => clearInterval(interval);
  }, []);

  const isProduction = typeof window !== 'undefined' && window.location.hostname !== 'localhost';
  const onlineAgents = agents.filter((a: Agent) => a.isOnline !== false);
  const recentTasks = mockTasks.slice(0, 5);

  if (loading) {
    return (
      <div className="space-y-8 animate-in fade-in duration-700">
        <div className="h-8 w-48 bg-white/5 rounded-lg animate-pulse mb-6" />
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
          {[1,2,3,4].map(i => <div key={i} className="h-32 bg-white/5 rounded-lg animate-pulse" />)}
        </div>
        <div className="h-40 bg-white/5 rounded-2xl animate-pulse mb-8" />
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <div className="h-96 bg-white/5 rounded-lg animate-pulse" />
          <div className="h-96 bg-white/5 rounded-lg animate-pulse" />
        </div>
      </div>
    );
  }

  return (
    <div className="animate-in fade-in slide-in-from-bottom-2 duration-700">
      <h1 className="text-3xl font-bold text-white mb-6">Overview</h1>

      {/* KPI Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
        <KpiCard
          label="Receita Mensal"
          value="R$ 1.240"
          trend="+12%"
          trendUp
          icon={DollarSign}
          accentColor="#EF9F27"
        />
        <KpiCard
          label="Agentes Ativos"
          value={`${onlineAgents.length}`}
          trend={`${agents.length} total`}
          trendUp
          icon={Bot}
          accentColor="#7F77DD"
        />
        <KpiCard
          label="Tarefas Pendentes"
          value="12"
          trend="3 concluídas hoje"
          trendUp
          icon={ListTodo}
          accentColor="#378ADD"
        />
        <KpiCard
          label="Sistemas Onboarding"
          value="3 / 6"
          icon={Cpu}
          accentColor="#D85A30"
          progress={50}
        />
      </div>

      {/* NEW: DEPLOY STATUS CARD */}
      <div className="bg-black/30 border border-white/5 rounded-2xl p-6 backdrop-blur-md mb-8 relative overflow-hidden group">
        <div className="absolute top-0 right-0 w-64 h-64 bg-purple-500/5 rounded-full blur-3xl -mr-32 -mt-32" />
        
        <div className="flex items-center justify-between mb-6 relative z-10">
          <div className="flex items-center gap-3">
            <div className="p-2 bg-zinc-800 rounded-lg border border-white/10 text-zinc-400 group-hover:border-purple-500/50 transition-colors">
              <Cloud size={18} />
            </div>
            <div>
              <h3 className="text-sm font-bold text-white uppercase tracking-wider">Status do Ecossistema</h3>
              <p className="text-[10px] text-zinc-500 font-medium">Sincronização em tempo real (30s)</p>
            </div>
          </div>
          <div className={cn("px-3 py-1 rounded-full text-[10px] font-bold uppercase tracking-widest flex items-center gap-1.5 backdrop-blur-md border", 
            isProduction 
              ? "bg-orange-500/10 text-orange-400 border-orange-500/20" 
              : "bg-blue-500/10 text-blue-400 border-blue-500/20"
          )}>
            <div className={cn("w-1 h-1 rounded-full", isProduction ? "bg-orange-400" : "bg-blue-400")} />
            {isProduction ? "Produção" : "Desenvolvimento"}
          </div>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 relative z-10">
          <StatusIndicator 
            label="Frontend" 
            status={isProduction ? "healthy" : "not-configured"} 
            url={isProduction ? "aethrium-hub.vercel.app" : "Vercel Local Mode"} 
            icon={Globe}
          />
          <StatusIndicator 
            label="Backend" 
            status={health?.status === "ok" ? "healthy" : "unreachable"} 
            url={health?.status === "ok" ? (isProduction ? "render-api.aethrium.app" : "localhost:8001") : "API Offline"} 
            icon={Server}
          />
          <StatusIndicator 
            label="Database" 
            status="healthy" 
            url="Supabase PostgreSQL" 
            icon={Database}
          />
          <StatusIndicator 
            label="Vector DB" 
            status={health?.status === "ok" ? "healthy" : "not-configured"} 
            url={health?.status === "ok" ? "Pinecone Region Ready" : "Unreachable"} 
            icon={Cpu}
          />
        </div>
      </div>

      {/* Two Column Layout */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Active Agents */}
        <div>
          <SectionHeader title="Agentes Ativos" subtitle="Atualmente respondendo" />
          <div className="space-y-3">
            {onlineAgents.length > 0 ? onlineAgents.map((agent) => (
              <div
                key={agent.slug}
                className="bg-black/20 border border-white/5 rounded-xl p-4 hover:border-white/10 transition-all hover:translate-x-1 group"
              >
                <div className="flex items-center gap-3 mb-2">
                  <AgentAvatar
                    name={agent.displayName || agent.slug}
                    color={agent.color || "#888"}
                    size="sm"
                    isOnline={true}
                  />
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2">
                      <span className="text-sm font-semibold text-white">
                        {agent.displayName || agent.slug}
                      </span>
                      <StatusBadge variant={agent.role as any || "Especialista"} />
                    </div>
                  </div>
                  <span className="text-[10px] text-zinc-500 font-mono bg-white/5 px-2 py-0.5 rounded border border-white/5">
                    {agent.model}
                  </span>
                </div>
                <p className="text-[11px] font-medium text-zinc-500 truncate pl-9">
                  Monitorando logs e processos do servidor...
                </p>
              </div>
            )) : (
              <div className="p-8 text-center bg-white/5 rounded-xl border border-white/5">
                <AlertCircle className="w-8 h-8 text-zinc-600 mx-auto mb-2" />
                <p className="text-zinc-500 text-sm">Nenhum agente online no momento.</p>
              </div>
            )}
          </div>
        </div>

        {/* Recent Tasks */}
        <div>
          <SectionHeader title="Atividade Recente" subtitle="Últimas 5 interações" />
          <div className="space-y-3">
            {recentTasks.map((task) => (
              <div
                key={task.id}
                className="bg-black/20 border border-white/5 rounded-xl p-4 hover:border-white/10 transition-all hover:shadow-lg shadow-black/50"
              >
                <div className="flex items-start justify-between gap-3">
                  <div className="flex items-start gap-3 min-w-0">
                    <AgentAvatar
                      name={task.ownerName}
                      color={task.ownerColor}
                      size="sm"
                    />
                    <div className="min-w-0">
                      <p className="text-sm font-semibold text-white truncate">
                        {task.title}
                      </p>
                      <p className="text-xs text-zinc-500 mt-0.5">
                        {task.ownerName} · {new Date(task.createdAt).toLocaleDateString()}
                      </p>
                    </div>
                  </div>
                  <StatusBadge variant={task.status as any} />
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
