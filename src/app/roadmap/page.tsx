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
const currentWeek = 4; // 0-indexed

const cumulativeRevenue = [0, 300, 790, 1240, 1600, 2100, 2650, 3200];

const dependencies = [
  { from: "Dodge/Critical/Reflect", to: "Mining/Refinement" },
  { from: "VIP System", to: "Guild Points" },
  { from: "Reset System", to: "Guild Points" },
];

export default function RoadmapPage() {
  return (
    <div>
      <SectionHeader title="Roadmap" subtitle="8-week implementation timeline" />

      {/* Timeline */}
      <div className="bg-[#111111] border border-[#222222] rounded-lg p-5 mb-6 overflow-x-auto">
        {/* Week Headers */}
        <div className="grid gap-0" style={{ gridTemplateColumns: `160px repeat(8, 1fr)` }}>
          <div className="text-xs text-[#888780] py-2">System</div>
          {weeks.map((w, i) => (
            <div
              key={w}
              className={`text-xs text-center py-2 border-l border-[#222222] ${
                i === currentWeek ? "text-[#7F77DD] font-semibold bg-[#7F77DD]/5" : "text-[#888780]"
              }`}
            >
              {w}
              {i === 7 && (
                <div className="text-[9px] text-[#D85A30] mt-0.5">🚀 MVP</div>
              )}
            </div>
          ))}

          {/* System Rows */}
          {systems.map((s) => (
            <>
              <div key={`label-${s.name}`} className="text-xs text-white py-3 flex items-center truncate pr-2">
                {s.name}
              </div>
              {weeks.map((_, i) => (
                <div
                  key={`cell-${s.name}-${i}`}
                  className={`border-l border-[#222222] py-3 px-0.5 ${
                    i === currentWeek ? "bg-[#7F77DD]/5" : ""
                  }`}
                >
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

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
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

        {/* Revenue Projection */}
        <div className="bg-[#111111] border border-[#222222] rounded-lg p-5">
          <h3 className="text-sm font-medium text-white mb-4">Cumulative Revenue Projection</h3>
          <div className="space-y-2">
            {weeks.map((w, i) => (
              <div key={w} className="flex items-center gap-3">
                <span className={`text-xs w-8 ${i === currentWeek ? "text-[#7F77DD] font-bold" : "text-[#888780]"}`}>
                  {w}
                </span>
                <div className="flex-1 h-4 bg-[#1a1a1a] rounded-full overflow-hidden">
                  <div
                    className="h-full rounded-full transition-all"
                    style={{
                      width: `${(cumulativeRevenue[i] / 3200) * 100}%`,
                      backgroundColor: i <= currentWeek ? "#1D9E75" : "#EF9F27",
                      opacity: i <= currentWeek ? 1 : 0.4,
                    }}
                  />
                </div>
                <span className="text-xs text-[#888780] w-16 text-right">
                  R$ {cumulativeRevenue[i].toLocaleString()}
                </span>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
