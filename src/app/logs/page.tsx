"use client";

import { useState, useEffect, useRef } from "react";
import { SectionHeader } from "@/components/section-header";
type LogType = "LOGIN" | "LOGOUT" | "COMBAT" | "TRADE" | "VIP" | "RESET" | "SYSTEM";

interface LogEntry {
  id: string;
  timestamp: string;
  type: LogType;
  message: string;
  player?: string;
}

const logTypeColors: Record<LogType, string> = {
  LOGIN: "#378ADD",
  LOGOUT: "#378ADD",
  COMBAT: "#D85A30",
  TRADE: "#1D9E75",
  VIP: "#EF9F27",
  RESET: "#7F77DD",
  SYSTEM: "#888780",
};
import { Download, Pause, Play } from "lucide-react";
import { BACKEND_URL } from "@/lib/api";

const allTypes: LogType[] = ["LOGIN", "LOGOUT", "COMBAT", "TRADE", "VIP", "RESET", "SYSTEM"];

export default function LogsPage() {
  const [logs, setLogs] = useState<LogEntry[]>([]);
  const [filters, setFilters] = useState<Set<LogType>>(new Set(allTypes));
  const [search, setSearch] = useState("");
  const [autoScroll, setAutoScroll] = useState(true);
  const scrollRef = useRef<HTMLDivElement>(null);

  // Live stream
  useEffect(() => {
    const evtSource = new EventSource(`${BACKEND_URL}/logs/stream`);
    evtSource.onmessage = (e) => {
      const entry = JSON.parse(e.data);
      setLogs((prev) => [...prev.slice(-200), entry]);
    };
    return () => evtSource.close();
  }, []);

  useEffect(() => {
    if (autoScroll && scrollRef.current) {
      scrollRef.current.scrollTop = scrollRef.current.scrollHeight;
    }
  }, [logs, autoScroll]);

  const toggleFilter = (type: LogType) => {
    setFilters((prev) => {
      const next = new Set(prev);
      if (next.has(type)) next.delete(type);
      else next.add(type);
      return next;
    });
  };

  const filtered = logs.filter(
    (l) =>
      filters.has(l.type) &&
      (search === "" || l.message.toLowerCase().includes(search.toLowerCase()))
  );

  const exportLogs = () => {
    const text = filtered
      .map((l) => `[${l.timestamp}] [${l.type}] ${l.message}`)
      .join("\n");
    const blob = new Blob([text], { type: "text/plain" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = "server-logs.txt";
    a.click();
    URL.revokeObjectURL(url);
  };

  return (
    <div>
      <SectionHeader
        title="Server Logs"
        subtitle="Live game server event feed"
        action={
          <div className="flex gap-2">
            <button
              onClick={() => setAutoScroll(!autoScroll)}
              className="flex items-center gap-1.5 text-xs px-3 py-1.5 rounded bg-[#1a1a1a] text-[#888780] hover:text-white border border-[#222222] transition-colors"
            >
              {autoScroll ? <Pause className="w-3 h-3" /> : <Play className="w-3 h-3" />}
              {autoScroll ? "Pause" : "Resume"}
            </button>
            <button
              onClick={exportLogs}
              className="flex items-center gap-1.5 text-xs px-3 py-1.5 rounded bg-[#1a1a1a] text-[#888780] hover:text-white border border-[#222222] transition-colors"
            >
              <Download className="w-3 h-3" /> Export .txt
            </button>
          </div>
        }
      />

      {/* Filter Bar */}
      <div className="flex flex-wrap items-center gap-2 mb-3">
        {allTypes.map((type) => (
          <label key={type} className="flex items-center gap-1.5 text-xs cursor-pointer select-none">
            <input
              type="checkbox"
              checked={filters.has(type)}
              onChange={() => toggleFilter(type)}
              className="accent-[#7F77DD] w-3 h-3"
            />
            <span
              className="px-1.5 py-0.5 rounded text-[10px] font-medium"
              style={{
                backgroundColor: logTypeColors[type] + "20",
                color: logTypeColors[type],
              }}
            >
              {type}
            </span>
          </label>
        ))}
        <input
          type="text"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          placeholder="Search logs..."
          className="mt-2 sm:mt-0 sm:ml-auto bg-[#0a0a0a] border border-[#222222] rounded px-3 py-1 text-xs text-white placeholder:text-[#888780]/40 w-full sm:w-48"
        />
      </div>

      {/* Log Viewer Placeholder */}
      <div className="bg-[#111111] border border-[#222222] rounded-lg p-12 flex flex-col items-center justify-center text-center space-y-4 min-h-[400px]">
        <div className="w-12 h-12 rounded-full bg-purple-500/10 flex items-center justify-center">
          <Play className="text-purple-500 w-6 h-6 animate-pulse" />
        </div>
        <div>
          <h3 className="text-white font-medium">Aguardando servidor online</h3>
          <p className="text-xs text-[#888780] mt-1 max-w-xs">
            O fluxo de logs em tempo real começará assim que houver uma conexão ativa com o servidor de jogo.
          </p>
        </div>
      </div>
    </div>
  );
}
