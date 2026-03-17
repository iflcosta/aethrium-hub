"use client";

import { useEffect, useState } from "react";
import { KpiCard } from "@/components/kpi-card";
import { SectionHeader } from "@/components/section-header";
import { AgentAvatar } from "@/components/agent-avatar";
import { StatusBadge } from "@/components/status-badge";
import { DollarSign, Bot, ListTodo, Cpu } from "lucide-react";
import { mockTasks } from "@/lib/mock/tasks";

interface Agent {
  slug: string;
  displayName: string;
  model: string;
  role: string;
  color: string;
  isOnline: boolean;
}

export default function OverviewPage() {
  const [agents, setAgents] = useState<Agent[]>([]);

  useEffect(() => {
    fetch("/api/agents")
      .then((r) => r.json())
      .then((data) => setAgents(Array.isArray(data) ? data : []))
      .catch(() => {});
  }, []);

  const onlineAgents = agents.filter((a) => a.isOnline);
  const recentTasks = mockTasks.slice(0, 5);

  return (
    <div>
      <h1 className="text-2xl font-bold text-white mb-6">Overview</h1>

      {/* KPI Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
        <KpiCard
          label="Monthly Revenue"
          value="R$ 1.240"
          trend="+12%"
          trendUp
          icon={DollarSign}
          accentColor="#EF9F27"
        />
        <KpiCard
          label="Active Agents"
          value={`${onlineAgents.length}`}
          trend={`${agents.length} total`}
          trendUp
          icon={Bot}
          accentColor="#7F77DD"
        />
        <KpiCard
          label="Tasks in Progress"
          value="12"
          trend="3 completed today"
          trendUp
          icon={ListTodo}
          accentColor="#378ADD"
        />
        <KpiCard
          label="Systems"
          value="3 / 6"
          icon={Cpu}
          accentColor="#D85A30"
          progress={50}
        />
      </div>

      {/* Two Column Layout */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Active Agents */}
        <div>
          <SectionHeader title="Active Agents" subtitle="Currently online" />
          <div className="space-y-3">
            {onlineAgents.map((agent) => (
              <div
                key={agent.slug}
                className="bg-[#111111] border border-[#222222] rounded-lg p-4 hover:border-[#333333] transition-colors group"
              >
                <div className="flex items-center gap-3 mb-2">
                  <AgentAvatar
                    name={agent.displayName}
                    color={agent.color}
                    size="sm"
                    isOnline={agent.isOnline}
                  />
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2">
                      <span className="text-sm font-medium text-white">
                        {agent.displayName}
                      </span>
                      <StatusBadge variant={agent.role as any} />
                    </div>
                  </div>
                  <span className="text-[10px] text-[#888780] font-mono">
                    {agent.model}
                  </span>
                </div>
                <p className="text-xs font-mono text-[#888780] truncate pl-9">
                  Processing task assignments...
                </p>
              </div>
            ))}
          </div>
        </div>

        {/* Recent Tasks */}
        <div>
          <SectionHeader title="Recent Tasks" subtitle="Last 5 tasks" />
          <div className="space-y-3">
            {recentTasks.map((task) => (
              <div
                key={task.id}
                className="bg-[#111111] border border-[#222222] rounded-lg p-4 hover:border-[#333333] transition-colors"
              >
                <div className="flex items-start justify-between gap-3">
                  <div className="flex items-start gap-3 min-w-0">
                    <AgentAvatar
                      name={task.ownerName}
                      color={task.ownerColor}
                      size="sm"
                    />
                    <div className="min-w-0">
                      <p className="text-sm font-medium text-white truncate">
                        {task.title}
                      </p>
                      <p className="text-xs text-[#888780] mt-0.5">
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
