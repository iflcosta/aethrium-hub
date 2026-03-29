"use client";

import { useEffect, useState, useRef } from "react";
import { AgentAvatar } from "@/components/agent-avatar";
import { StatusBadge } from "@/components/status-badge";
import { SectionHeader } from "@/components/section-header";
import { backendApi, BACKEND_URL } from "@/lib/api";
import { useProjectStore } from "@/store/useProjectStore";
import { Loader2, X, Check } from "lucide-react";

interface Agent {
  slug: string;
  displayName: string;
  model: string;
  role: string;
  color: string;
  isOnline: boolean;
  tasksCompleted: number;
  tokensUsed: number;
}

type Priority = "LOW" | "MEDIUM" | "HIGH" | "CRITICAL";

const priorityColors = ["#888780", "#378ADD", "#EF9F27", "#D85A30"];

function ThoughtStreamPanel({ slug }: { slug: string }) {
  const [chunks, setChunks] = useState<string[]>([]);
  const scrollRef = useRef<HTMLDivElement>(null);
  const containerRef = useRef<HTMLDivElement>(null);
  const [paused, setPaused] = useState(false);
  const [visible, setVisible] = useState(false);
  const evtRef = useRef<EventSource | null>(null);

  useEffect(() => {
    const observer = new IntersectionObserver(
      ([entry]) => setVisible(entry.isIntersecting),
      { threshold: 0.1 }
    );
    if (containerRef.current) observer.observe(containerRef.current);
    return () => observer.disconnect();
  }, []);

  useEffect(() => {
    if (!visible) { evtRef.current?.close(); evtRef.current = null; return; }
    const es = new EventSource(`${BACKEND_URL}/agents/${slug}/stream`);
    evtRef.current = es;
    es.onmessage = (e) => {
      const data = JSON.parse(e.data);
      setChunks((prev) => [...prev.slice(-20), data.chunk]);
    };
    return () => { es.close(); evtRef.current = null; };
  }, [slug, visible]);

  useEffect(() => {
    if (!paused && scrollRef.current) {
      scrollRef.current.scrollTop = scrollRef.current.scrollHeight;
    }
  }, [chunks, paused]);

  return (
    <div ref={containerRef}>
      <div
        ref={scrollRef}
        className="h-28 overflow-y-auto thought-stream bg-[#0a0a0a] rounded border border-[#222222] p-2"
        onMouseEnter={() => setPaused(true)}
        onMouseLeave={() => setPaused(false)}
      >
        {chunks.length === 0 && (
          <span className="text-[#888780]/40 text-[11px]">
            {visible ? "Waiting for stream..." : "Scroll into view to connect"}
          </span>
        )}
        {chunks.map((c, i) => (
          <div key={i} className="chunk text-[11px] leading-5">{c}</div>
        ))}
      </div>
    </div>
  );
}

function AssignTaskForm({
  agentSlug,
  projectSlug,
  onDone,
  onCancel,
}: {
  agentSlug: string;
  projectSlug: string;
  onDone: () => void;
  onCancel: () => void;
}) {
  const [title, setTitle]     = useState("");
  const [desc, setDesc]       = useState("");
  const [prio, setPrio]       = useState<Priority>("MEDIUM");
  const [saving, setSaving]   = useState(false);
  const [error, setError]     = useState("");
  const [done, setDone]       = useState(false);

  const handleSubmit = async () => {
    if (!title.trim()) { setError("Título é obrigatório."); return; }
    setSaving(true);
    setError("");
    try {
      await backendApi.createTask({
        title: title.trim(),
        description: desc.trim(),
        owner_slug: agentSlug,
        priority: prio,
        context: { project_slug: projectSlug },
      });
      setDone(true);
      setTimeout(onDone, 800);
    } catch {
      setError("Erro ao criar tarefa.");
    } finally {
      setSaving(false);
    }
  };

  if (done) {
    return (
      <div className="flex items-center justify-center gap-2 py-3 text-[#1D9E75] text-xs">
        <Check className="w-4 h-4" /> Tarefa criada!
      </div>
    );
  }

  return (
    <div className="border-t border-[#222] pt-3 mt-1 space-y-2 animate-in fade-in duration-150">
      <div className="flex items-center justify-between mb-1">
        <span className="text-[10px] text-[#888780] uppercase tracking-wider">Nova Tarefa</span>
        <button onClick={onCancel} className="p-0.5 rounded hover:bg-[#222] text-[#888780] hover:text-white">
          <X className="w-3 h-3" />
        </button>
      </div>

      <input
        type="text"
        value={title}
        onChange={e => setTitle(e.target.value)}
        placeholder="Título da tarefa..."
        className="w-full bg-[#0a0a0a] border border-[#222] rounded px-3 py-1.5 text-xs text-white placeholder:text-[#444] focus:border-[#7F77DD] focus:outline-none"
      />
      <textarea
        value={desc}
        onChange={e => setDesc(e.target.value)}
        placeholder="Descrição (opcional)..."
        rows={2}
        className="w-full bg-[#0a0a0a] border border-[#222] rounded px-3 py-1.5 text-xs text-white placeholder:text-[#444] focus:border-[#7F77DD] focus:outline-none resize-none"
      />

      <div className="grid grid-cols-4 gap-1">
        {(["LOW", "MEDIUM", "HIGH", "CRITICAL"] as Priority[]).map((p, i) => (
          <button
            key={p}
            onClick={() => setPrio(p)}
            className={`text-[9px] py-1 rounded border transition-colors ${
              prio === p ? "text-white" : "border-[#222] text-[#888780] hover:text-white"
            }`}
            style={prio === p ? { backgroundColor: priorityColors[i] + "33", borderColor: priorityColors[i] + "66", color: priorityColors[i] } : {}}
          >
            {p === "CRITICAL" ? "CRIT" : p}
          </button>
        ))}
      </div>

      {error && <p className="text-[10px] text-[#D85A30]">{error}</p>}

      <button
        onClick={handleSubmit}
        disabled={saving}
        className="w-full text-xs py-1.5 rounded bg-[#7F77DD] text-white hover:bg-[#6b63cc] disabled:opacity-50 transition-colors flex items-center justify-center gap-1"
      >
        {saving ? <Loader2 className="w-3 h-3 animate-spin" /> : null}
        {saving ? "Criando..." : "Criar Tarefa"}
      </button>
    </div>
  );
}

export default function AgentsPage() {
  const { activeProject } = useProjectStore();
  const projectSlug = activeProject?.slug ?? 'baiak-thunder-86';

  const [agents, setAgents]         = useState<Agent[]>([]);
  const [assigningSlug, setAssigningSlug] = useState<string | null>(null);

  useEffect(() => {
    backendApi.getAgents().then(setAgents).catch(() => {});
  }, []);

  return (
    <div>
      <SectionHeader title="Agents" subtitle="AI development team" />

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        {agents.map((agent) => (
          <div
            key={agent.slug}
            className="bg-[#111111] border border-[#222222] rounded-lg overflow-hidden hover:border-[#333333] transition-colors"
          >
            {/* Header */}
            <div className="flex items-center gap-3 p-4" style={{ borderLeft: `3px solid ${agent.color || "#888780"}` }}>
              <AgentAvatar name={agent.displayName} color={agent.color} size="lg" isOnline={agent.isOnline} />
              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-2 mb-1">
                  <span className="text-sm font-semibold text-white">{agent.displayName}</span>
                  <StatusBadge variant={agent.role as any} />
                  <span className="text-[10px] font-mono text-[#888780] bg-[#1a1a1a] px-1.5 py-0.5 rounded">
                    {agent.model}
                  </span>
                </div>
                <div className="flex items-center gap-2">
                  <span className={`w-2 h-2 rounded-full ${agent.isOnline ? "bg-[#1D9E75]" : "bg-[#888780]/40"}`} />
                  <span className="text-xs text-[#888780]">{agent.isOnline ? "Online" : "Offline"}</span>
                </div>
              </div>
            </div>

            {/* Thought Stream */}
            <div className="px-4 pb-3">
              {agent.isOnline ? (
                <ThoughtStreamPanel slug={agent.slug} />
              ) : (
                <div className="h-28 bg-[#0a0a0a] rounded border border-[#222222] p-2 flex items-center justify-center">
                  <span className="text-xs text-[#888780]/40">Agent offline</span>
                </div>
              )}
            </div>

            {/* Stats + Assign */}
            <div className="px-4 pb-4 border-t border-[#222222] pt-3">
              <div className="flex items-center justify-between mb-2">
                <div className="flex gap-4 text-xs text-[#888780]">
                  <span>
                    <span className="text-white font-medium">{agent.tasksCompleted || 0}</span> tasks
                  </span>
                  <span>
                    <span className="text-white font-medium">
                      {agent.tokensUsed > 0 ? (agent.tokensUsed / 1000).toFixed(0) + "k" : "0"}
                    </span>{" "}tokens
                  </span>
                </div>
                {assigningSlug !== agent.slug && (
                  <button
                    onClick={() => setAssigningSlug(agent.slug)}
                    className="text-xs px-3 py-1.5 rounded bg-[#1a1a1a] text-[#888780] hover:text-white hover:bg-[#222222] transition-colors border border-[#222222]"
                  >
                    Assign task
                  </button>
                )}
              </div>

              {assigningSlug === agent.slug && (
                <AssignTaskForm
                  agentSlug={agent.slug}
                  projectSlug={projectSlug}
                  onDone={() => setAssigningSlug(null)}
                  onCancel={() => setAssigningSlug(null)}
                />
              )}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
