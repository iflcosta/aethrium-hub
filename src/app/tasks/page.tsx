"use client";

import { useState, useEffect } from "react";
import { backendApi } from "@/lib/api";
import { SectionHeader } from "@/components/section-header";
import { AgentAvatar } from "@/components/agent-avatar";
import { StatusBadge } from "@/components/status-badge";
import { X, ChevronRight, Loader2, Trash2 } from "lucide-react";

type TaskStatus = "PENDING" | "RUNNING" | "COMPLETED" | "FAILED";

interface Task {
  id: string;
  title: string;
  description?: string;
  status: TaskStatus;
  priority: number;
  contextSnapshot?: Record<string, unknown>;
  createdAt: string;
  owner?: {
    slug: string;
    displayName: string;
    model: string;
    role: string;
  };
}

const columns: { status: TaskStatus; label: string; color: string }[] = [
  { status: "PENDING", label: "Pending", color: "#EF9F27" },
  { status: "RUNNING", label: "In Progress", color: "#378ADD" },
  { status: "COMPLETED", label: "Done", color: "#1D9E75" },
  { status: "FAILED", label: "Failed", color: "#D85A30" },
];

const agentColors: Record<string, string> = {
  carlos: "#7F77DD",
  rafael: "#1D9E75",
  viktor: "#378ADD",
  sophia: "#D85A30",
  thiago: "#888780",
  beatriz: "#EF9F27",
  lucas: "#EF9F27",
  mariana: "#888780",
  amanda: "#888780",
  leonardo: "#888780",
};

function priorityDot(p: number) {
  const colors = ["#888780", "#378ADD", "#EF9F27", "#D85A30"];
  return <span className="w-2 h-2 rounded-full shrink-0" style={{ backgroundColor: colors[p - 1] || colors[0] }} />;
}

export default function TasksPage() {
  const [tasks, setTasks] = useState<Task[]>([]);
  const [agents, setAgents] = useState<{slug: string; displayName: string}[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedTask, setSelectedTask] = useState<Task | null>(null);
  const [jsonOpen, setJsonOpen] = useState(false);
  const [confirmDelete, setConfirmDelete] = useState(false);
  const [deleting, setDeleting] = useState(false);

  useEffect(() => {
    const load = async () => {
      try {
        const [taskData, agentData] = await Promise.all([
          backendApi.getTasks({ limit: 100 }),
          backendApi.getAgents(),
        ]);
        setTasks(Array.isArray(taskData) ? taskData : []);
        setAgents(Array.isArray(agentData) ? agentData : []);
      } catch (err) {
        console.error("Failed to fetch tasks", err);
      } finally {
        setLoading(false);
      }
    };
    load();
    const interval = setInterval(load, 30_000);
    return () => clearInterval(interval);
  }, []);

  const handleDelete = async () => {
    if (!selectedTask) return;
    setDeleting(true);
    try {
      await backendApi.deleteTask(selectedTask.id);
      setTasks(prev => prev.filter(t => t.id !== selectedTask.id));
      setSelectedTask(null);
      setConfirmDelete(false);
    } catch (err) {
      console.error("Failed to delete task", err);
    } finally {
      setDeleting(false);
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <Loader2 className="w-6 h-6 animate-spin text-[#7F77DD]" />
      </div>
    );
  }

  return (
    <div className="flex gap-0">
      {/* Main Content */}
      <div className={selectedTask ? "flex-1 pr-4" : "flex-1"}>
        <SectionHeader
          title="Tasks"
          subtitle="Kanban board"
          action={
            <button className="text-xs px-3 py-1.5 rounded bg-[#7F77DD] text-white hover:bg-[#6b63cc] transition-colors">
              + New Task
            </button>
          }
        />

        <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-4">
          {columns.map((col) => {
            const colTasks = tasks.filter((t) => t.status === col.status);
            return (
              <div key={col.status}>
                <div className="flex items-center gap-2 mb-3 px-1">
                  <span className="w-2 h-2 rounded-full" style={{ backgroundColor: col.color }} />
                  <span className="text-xs font-medium text-[#888780] uppercase tracking-wider">
                    {col.label}
                  </span>
                  <span className="text-[10px] text-[#888780]/60 ml-auto">{colTasks.length}</span>
                </div>
                <div className="space-y-2">
                  {colTasks.map((task) => {
                    const ownerSlug = task.owner?.slug || "";
                    const ownerName = task.owner?.displayName || ownerSlug;
                    const ownerColor = agentColors[ownerSlug] || "#888780";
                    return (
                      <div
                        key={task.id}
                        onClick={() => setSelectedTask(task)}
                        className="bg-[#111111] border border-[#222222] rounded-lg p-3 cursor-pointer hover:border-[#333333] transition-colors group"
                      >
                        <div className="flex items-start gap-2 mb-2">
                          {priorityDot(task.priority)}
                          <span className="text-sm text-white font-medium leading-tight flex-1">
                            {task.title}
                          </span>
                        </div>
                        <div className="flex items-center gap-2">
                          <AgentAvatar name={ownerName} color={ownerColor} size="sm" />
                          <span className="text-[11px] text-[#888780] truncate">{ownerName}</span>
                          <span className="text-[10px] text-[#888780]/50 ml-auto">
                            {new Date(task.createdAt).toLocaleDateString("pt-BR", { day: "2-digit", month: "short" })}
                          </span>
                        </div>
                      </div>
                    );
                  })}
                  {colTasks.length === 0 && (
                    <div className="text-[11px] text-[#888780]/40 px-1 py-3 text-center border border-dashed border-[#222222] rounded-lg">
                      No tasks
                    </div>
                  )}
                </div>
              </div>
            );
          })}
        </div>
      </div>

      {/* Right Panel */}
      {selectedTask && (
        <div className="w-80 shrink-0 bg-[#111111] border-l border-[#222222] p-4 overflow-y-auto animate-in slide-in-from-right-4 duration-200">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-sm font-semibold text-white">Task Details</h3>
            <button
              onClick={() => { setSelectedTask(null); setConfirmDelete(false); }}
              className="p-1 rounded hover:bg-[#1a1a1a] text-[#888780] hover:text-white"
            >
              <X className="w-4 h-4" />
            </button>
          </div>

          <div className="space-y-4">
            <div>
              <h4 className="text-base font-semibold text-white mb-1">{selectedTask.title}</h4>
              <StatusBadge variant={selectedTask.status as any} />
            </div>

            {selectedTask.description && (
              <div>
                <p className="text-xs text-[#888780] uppercase tracking-wider mb-1">Description</p>
                <p className="text-sm text-[#e5e5e5]/80">{selectedTask.description}</p>
              </div>
            )}

            <div>
              <p className="text-xs text-[#888780] uppercase tracking-wider mb-1">Owner</p>
              <div className="flex items-center gap-2">
                <AgentAvatar
                  name={selectedTask.owner?.displayName || selectedTask.owner?.slug || "?"}
                  color={agentColors[selectedTask.owner?.slug || ""] || "#888780"}
                  size="sm"
                />
                <span className="text-sm text-white">{selectedTask.owner?.displayName || selectedTask.owner?.slug}</span>
              </div>
            </div>

            {selectedTask.contextSnapshot && (
              <div>
                <button
                  onClick={() => setJsonOpen(!jsonOpen)}
                  className="flex items-center gap-1 text-xs text-[#888780] uppercase tracking-wider mb-1 hover:text-white"
                >
                  <ChevronRight className={`w-3 h-3 transition-transform ${jsonOpen ? "rotate-90" : ""}`} />
                  Context Snapshot
                </button>
                {jsonOpen && (
                  <pre className="text-[11px] font-mono bg-[#0a0a0a] rounded border border-[#222222] p-2 overflow-x-auto text-[#888780]">
                    {JSON.stringify(selectedTask.contextSnapshot, null, 2)}
                  </pre>
                )}
              </div>
            )}

            {/* Delete Section */}
            <div className="border-t border-[#222222] pt-4">
              {!confirmDelete ? (
                <button
                  onClick={() => setConfirmDelete(true)}
                  className="w-full flex items-center justify-center gap-2 text-xs px-3 py-1.5 rounded border border-[#D85A30]/30 text-[#D85A30]/70 hover:bg-[#D85A30]/10 hover:text-[#D85A30] hover:border-[#D85A30]/60 transition-colors"
                >
                  <Trash2 className="w-3 h-3" /> Deletar tarefa
                </button>
              ) : (
                <div className="space-y-2">
                  <p className="text-xs text-[#D85A30] text-center">Confirmar exclusão? Esta ação também remove as execuções.</p>
                  <div className="flex gap-2">
                    <button
                      onClick={() => setConfirmDelete(false)}
                      className="flex-1 text-xs px-3 py-1.5 rounded bg-[#1a1a1a] border border-[#222222] text-[#888780] hover:text-white transition-colors"
                    >
                      Cancelar
                    </button>
                    <button
                      onClick={handleDelete}
                      disabled={deleting}
                      className="flex-1 text-xs px-3 py-1.5 rounded bg-[#D85A30] text-white hover:bg-[#c04e27] disabled:opacity-50 transition-colors flex items-center justify-center gap-1"
                    >
                      {deleting ? <Loader2 className="w-3 h-3 animate-spin" /> : <Trash2 className="w-3 h-3" />}
                      {deleting ? "Deletando..." : "Confirmar"}
                    </button>
                  </div>
                </div>
              )}
            </div>

            {/* Handoff Section */}
            <div className="border-t border-[#222222] pt-4">
              <p className="text-xs text-[#888780] uppercase tracking-wider mb-2">Handoff</p>
              <div className="flex items-center gap-2 mb-2 text-xs text-[#888780]">
                <span className="text-white">{selectedTask.owner?.displayName || selectedTask.owner?.slug}</span>
                <ChevronRight className="w-3 h-3" />
                <select className="bg-[#1a1a1a] border border-[#222222] rounded px-2 py-1 text-xs text-white">
                  <option value="">Select agent...</option>
                  {agents
                    .filter(a => a.slug !== selectedTask.owner?.slug)
                    .map(a => (
                      <option key={a.slug} value={a.slug}>{a.displayName}</option>
                    ))
                  }
                </select>
              </div>
              <input
                type="text"
                placeholder="Handoff reason..."
                className="w-full bg-[#1a1a1a] border border-[#222222] rounded px-3 py-1.5 text-xs text-white placeholder:text-[#888780]/40 mb-2"
              />
              <button className="w-full text-xs px-3 py-1.5 rounded bg-[#7F77DD] text-white hover:bg-[#6b63cc] transition-colors">
                Initiate Handoff
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
