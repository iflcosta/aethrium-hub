"use client";

import { useState } from "react";
import { mockTasks, type MockTask, type MockTaskStatus } from "@/lib/mock/tasks";
import { SectionHeader } from "@/components/section-header";
import { AgentAvatar } from "@/components/agent-avatar";
import { StatusBadge } from "@/components/status-badge";
import { X, ChevronRight } from "lucide-react";

const columns: { status: MockTaskStatus; label: string; color: string }[] = [
  { status: "PENDING", label: "Pending", color: "#EF9F27" },
  { status: "RUNNING", label: "In Progress", color: "#378ADD" },
  { status: "COMPLETED", label: "Done", color: "#1D9E75" },
  { status: "FAILED", label: "Failed", color: "#D85A30" },
];

function priorityDot(p: number) {
  const colors = ["#888780", "#378ADD", "#EF9F27", "#D85A30"];
  return <span className="w-2 h-2 rounded-full shrink-0" style={{ backgroundColor: colors[p] || colors[0] }} />;
}

export default function TasksPage() {
  const [selectedTask, setSelectedTask] = useState<MockTask | null>(null);
  const [jsonOpen, setJsonOpen] = useState(false);

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
            const tasks = mockTasks.filter((t) => t.status === col.status);
            return (
              <div key={col.status}>
                <div className="flex items-center gap-2 mb-3 px-1">
                  <span className="w-2 h-2 rounded-full" style={{ backgroundColor: col.color }} />
                  <span className="text-xs font-medium text-[#888780] uppercase tracking-wider">
                    {col.label}
                  </span>
                  <span className="text-[10px] text-[#888780]/60 ml-auto">{tasks.length}</span>
                </div>
                <div className="space-y-2">
                  {tasks.map((task) => (
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
                        <AgentAvatar name={task.ownerName} color={task.ownerColor} size="sm" />
                        <span className="text-[11px] text-[#888780] truncate">{task.ownerName}</span>
                        <span className="text-[10px] text-[#888780]/50 ml-auto">
                          {new Date(task.createdAt).toLocaleDateString("pt-BR", { day: "2-digit", month: "short" })}
                        </span>
                      </div>
                    </div>
                  ))}
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
              onClick={() => setSelectedTask(null)}
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

            <div>
              <p className="text-xs text-[#888780] uppercase tracking-wider mb-1">Description</p>
              <p className="text-sm text-[#e5e5e5]/80">{selectedTask.description}</p>
            </div>

            <div>
              <p className="text-xs text-[#888780] uppercase tracking-wider mb-1">Owner</p>
              <div className="flex items-center gap-2">
                <AgentAvatar name={selectedTask.ownerName} color={selectedTask.ownerColor} size="sm" />
                <span className="text-sm text-white">{selectedTask.ownerName}</span>
              </div>
            </div>

            {selectedTask.systemTag && (
              <div>
                <p className="text-xs text-[#888780] uppercase tracking-wider mb-1">System</p>
                <span className="text-xs font-mono bg-[#1a1a1a] text-[#888780] px-2 py-1 rounded border border-[#222222]">
                  {selectedTask.systemTag}
                </span>
              </div>
            )}

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

            {/* Handoff Section */}
            <div className="border-t border-[#222222] pt-4">
              <p className="text-xs text-[#888780] uppercase tracking-wider mb-2">Handoff</p>
              <div className="flex items-center gap-2 mb-2 text-xs text-[#888780]">
                <span className="text-white">{selectedTask.ownerName}</span>
                <ChevronRight className="w-3 h-3" />
                <select className="bg-[#1a1a1a] border border-[#222222] rounded px-2 py-1 text-xs text-white">
                  <option>Select agent...</option>
                  <option>Carlos</option>
                  <option>Rafael</option>
                  <option>Sophia</option>
                  <option>Beatriz</option>
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

            {/* Log Feed */}
            <div className="border-t border-[#222222] pt-4">
              <p className="text-xs text-[#888780] uppercase tracking-wider mb-2">Activity Log</p>
              <div className="space-y-1.5 font-mono text-[11px] text-[#888780]">
                <div>[14:30] Task assigned to {selectedTask.ownerName}</div>
                <div>[14:32] Status changed to {selectedTask.status}</div>
                <div>[14:35] Context snapshot updated</div>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
