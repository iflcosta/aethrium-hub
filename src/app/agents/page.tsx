"use client";

import { useEffect, useState, useRef } from "react";
import { AgentAvatar } from "@/components/agent-avatar";
import { StatusBadge } from "@/components/status-badge";
import { SectionHeader } from "@/components/section-header";
import { mockAgents } from "@/lib/mock/agents";

interface Agent {
  slug: string;
  displayName: string;
  model: string;
  role: string;
  color: string;
  isOnline: boolean;
}

function ThoughtStreamPanel({ slug }: { slug: string }) {
  const [chunks, setChunks] = useState<string[]>([]);
  const scrollRef = useRef<HTMLDivElement>(null);
  const containerRef = useRef<HTMLDivElement>(null);
  const [paused, setPaused] = useState(false);
  const [visible, setVisible] = useState(false);
  const evtRef = useRef<EventSource | null>(null);

  // Only open SSE when card is visible in the viewport
  useEffect(() => {
    const observer = new IntersectionObserver(
      ([entry]) => setVisible(entry.isIntersecting),
      { threshold: 0.1 }
    );
    if (containerRef.current) observer.observe(containerRef.current);
    return () => observer.disconnect();
  }, []);

  useEffect(() => {
    if (!visible) {
      evtRef.current?.close();
      evtRef.current = null;
      return;
    }
    const es = new EventSource(`/api/agents/${slug}/stream`);
    evtRef.current = es;
    es.onmessage = (e) => {
      const data = JSON.parse(e.data);
      setChunks((prev) => [...prev.slice(-20), data.chunk]);
    };
    return () => {
      es.close();
      evtRef.current = null;
    };
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
        className="h-32 overflow-y-auto thought-stream bg-[#0a0a0a] rounded border border-[#222222] p-2"
        onMouseEnter={() => setPaused(true)}
        onMouseLeave={() => setPaused(false)}
      >
        {chunks.length === 0 && (
          <span className="text-[#888780]/40 text-[11px]">
            {visible ? "Waiting for stream..." : "Scroll into view to connect"}
          </span>
        )}
        {chunks.map((c, i) => (
          <div key={i} className="chunk text-[11px] leading-5">
            {c}
          </div>
        ))}
      </div>
    </div>
  );
}

export default function AgentsPage() {
  const [agents, setAgents] = useState<Agent[]>([]);
  const agentMeta = mockAgents;

  useEffect(() => {
    fetch("/api/agents")
      .then((r) => r.json())
      .then(setAgents)
      .catch(() => {});
  }, []);

  const getAgentMeta = (slug: string) =>
    agentMeta.find((a) => a.slug === slug);

  return (
    <div>
      <SectionHeader
        title="Agents"
        subtitle="AI development team overview"
      />

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        {agents.map((agent) => {
          const meta = getAgentMeta(agent.slug);
          const accentColors: Record<string, string> = {
            purple: "#7F77DD", teal: "#1D9E75", amber: "#EF9F27",
            coral: "#D85A30", blue: "#378ADD", gray: "#888780",
          };
          const accent = accentColors[agent.color] || "#888780";

          return (
            <div
              key={agent.slug}
              className="bg-[#111111] border border-[#222222] rounded-lg overflow-hidden hover:border-[#333333] transition-colors"
            >
              {/* Header */}
              <div className="flex items-center gap-3 p-4" style={{ borderLeft: `3px solid ${accent}` }}>
                <AgentAvatar
                  name={agent.displayName}
                  color={agent.color}
                  size="lg"
                  isOnline={agent.isOnline}
                />
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2 mb-1">
                    <span className="text-sm font-semibold text-white">
                      {agent.displayName}
                    </span>
                    <StatusBadge variant={agent.role as any} />
                    <span className="text-[10px] font-mono text-[#888780] bg-[#1a1a1a] px-1.5 py-0.5 rounded">
                      {agent.model}
                    </span>
                  </div>
                  <div className="flex items-center gap-2">
                    <span
                      className={`w-2 h-2 rounded-full ${agent.isOnline ? "bg-[#1D9E75]" : "bg-[#888780]/40"}`}
                    />
                    <span className="text-xs text-[#888780]">
                      {agent.isOnline ? "Online" : "Offline"}
                    </span>
                  </div>
                </div>
              </div>

              {/* Thought Stream */}
              <div className="px-4 pb-3">
                {agent.isOnline ? (
                  <ThoughtStreamPanel slug={agent.slug} />
                ) : (
                  <div className="h-32 bg-[#0a0a0a] rounded border border-[#222222] p-2 flex items-center justify-center">
                    <span className="text-xs text-[#888780]/40">Agent offline</span>
                  </div>
                )}
              </div>

              {/* Stats */}
              <div className="flex items-center justify-between px-4 py-3 border-t border-[#222222]">
                <div className="flex gap-4 text-xs text-[#888780]">
                  <span>
                    <span className="text-white font-medium">{meta?.tasksCompleted || 0}</span> tasks
                  </span>
                  <span>
                    <span className="text-white font-medium">
                      {meta ? (meta.tokensUsed / 1000).toFixed(0) + "k" : "0"}
                    </span>{" "}
                    tokens
                  </span>
                </div>
                <button className="text-xs px-3 py-1.5 rounded bg-[#1a1a1a] text-[#888780] hover:text-white hover:bg-[#222222] transition-colors border border-[#222222]">
                  Assign task
                </button>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
