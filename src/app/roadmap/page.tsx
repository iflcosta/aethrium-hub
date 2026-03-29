"use client";

import { SectionHeader } from "@/components/section-header";

const systems = [
  { name: "Dodge/Critical/Reflect", start: 0, duration: 3, status: "done", color: "#1D9E75" },
  { name: "VIP System", start: 1, duration: 3, status: "done", color: "#1D9E75" },
  { name: "Stamina Refill", start: 1, duration: 2, status: "done", color: "#1D9E75" },
  { name: "Reset System", start: 3, duration: 2, status: "progress", color: "#378ADD" },
  { name: "Guild Points", start: 4, duration: 2, status: "pending", color: "#EF9F27" },
  { name: "Mining/Refinement", start: 5, duration: 3, status: "pending", color: "#EF9F27" },
];

const weeks = ["W1", "W2", "W3", "W4", "W5", "W6", "W7", "W8"];

const dependencies = [
  { from: "Dodge/Critical/Reflect", to: "Mining/Refinement" },
  { from: "VIP System", to: "Guild Points" },
  { from: "Reset System", to: "Guild Points" },
];

export default function RoadmapPage() {
  return (
    <div>
      <SectionHeader title="Roadmap" subtitle="8-week implementation timeline — Baiak Thunder 8.6" />

      {/* Timeline */}
      <div className="bg-[#111111] border border-[#222222] rounded-lg p-5 mb-6 overflow-x-auto">
        <div className="grid gap-0" style={{ gridTemplateColumns: `160px repeat(8, 1fr)` }}>
          <div className="text-xs text-[#888780] py-2">System</div>
          {weeks.map((w) => (
            <div key={w} className="text-xs text-center py-2 border-l border-[#222222] text-[#888780]">
              {w}
            </div>
          ))}

          {systems.map((s) => (
            <>
              <div key={`label-${s.name}`} className="text-xs text-white py-3 flex items-center truncate pr-2">
                {s.name}
              </div>
              {weeks.map((_, i) => (
                <div key={`cell-${s.name}-${i}`} className="border-l border-[#222222] py-3 px-0.5">
                  {i >= s.start && i < s.start + s.duration && (
                    <div
                      className="h-6 rounded flex items-center justify-center text-[10px] font-medium text-white/80"
                      style={{ backgroundColor: s.color + "33", border: `1px solid ${s.color}55` }}
                    >
                      {i === s.start ? s.name.split("/")[0].split(" ")[0] : ""}
                    </div>
                  )}
                </div>
              ))}
            </>
          ))}
        </div>
      </div>

      {/* Dependencies */}
      <div className="bg-[#111111] border border-[#222222] rounded-lg p-5">
        <h3 className="text-sm font-medium text-white mb-4">Dependencies</h3>
        <div className="space-y-3">
          {dependencies.map((dep, i) => (
            <div key={i} className="flex items-center gap-2 text-xs">
              <span className="text-white bg-[#1a1a1a] px-2 py-1 rounded border border-[#222222]">
                {dep.from}
              </span>
              <span className="text-[#888780]">→</span>
              <span className="text-white bg-[#1a1a1a] px-2 py-1 rounded border border-[#222222]">
                {dep.to}
              </span>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
