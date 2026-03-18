"use client";

import { useState, useEffect, useRef } from "react";
import { SectionHeader } from "@/components/section-header";
import { mockLogs, logTypeColors, type LogEntry, type LogType } from "@/lib/mock/logs";
import { Download, Pause, Play } from "lucide-react";
import { BACKEND_URL } from "@/lib/api";

const allTypes: LogType[] = ["LOGIN", "LOGOUT", "COMBAT", "TRADE", "VIP", "RESET", "SYSTEM"];

export default function LogsPage() {
  const [logs, setLogs] = useState<LogEntry[]>(mockLogs);
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
      <div className="flex flex-wrap items-center gap-3 mb-4">
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
          className="ml-auto bg-[#0a0a0a] border border-[#222222] rounded px-3 py-1 text-xs text-white placeholder:text-[#888780]/40 w-48"
        />
      </div>

      {/* Log Viewer */}
      <div
        ref={scrollRef}
        className="bg-[#111111] border border-[#222222] rounded-lg overflow-y-auto font-mono text-[11px] leading-6"
        style={{ height: "calc(100vh - 220px)" }}
      >
        {filtered.map((log) => (
          <div
            key={log.id}
            className="flex items-start gap-2 px-3 py-0.5 hover:bg-[#1a1a1a] border-b border-[#222222]/30"
          >
            <span className="text-[#888780]/50 shrink-0 w-16">
              {log.timestamp.slice(11, 19)}
            </span>
            <span
              className="shrink-0 w-14 text-center text-[10px] font-medium rounded px-1"
              style={{
                backgroundColor: logTypeColors[log.type] + "20",
                color: logTypeColors[log.type],
              }}
            >
              {log.type}
            </span>
            <span className="text-[#e5e5e5]/80">{log.message}</span>
          </div>
        ))}
      </div>
    </div>
  );
}
