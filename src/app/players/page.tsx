"use client";

import React from "react";
import { SectionHeader } from "@/components/section-header";
import { KpiCard } from "@/components/kpi-card";
import { playersOnline7d, resetsPerDay, topPlayers, heatmapData, heatmapDays, playerStats } from "@/lib/mock/players";
import { Users, TrendingUp, UserCheck } from "lucide-react";
import {
  LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip,
  ResponsiveContainer, BarChart, Bar,
} from "recharts";

export default function PlayersPage() {
  return (
    <div>
      <SectionHeader title="Players" subtitle="Server population analytics" />

      {/* KPI Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 mb-6">
        <KpiCard label="Online Now" value={String(playerStats.onlineNow)} icon={Users} accentColor="#1D9E75" />
        <KpiCard label="Peak Today" value={String(playerStats.peakToday)} icon={TrendingUp} accentColor="#378ADD" />
        <KpiCard label="Total Accounts" value={String(playerStats.totalAccounts)} icon={UserCheck} accentColor="#7F77DD" />
      </div>

      {/* Charts Row */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6">
        {/* Online Chart */}
        <div className="bg-[#111111] border border-[#222222] rounded-lg p-5">
          <h3 className="text-sm font-medium text-white mb-4">Players Online — 7 Days</h3>
          <div className="h-56">
            <ResponsiveContainer width="100%" height="100%">
              <LineChart data={playersOnline7d}>
                <CartesianGrid strokeDasharray="3 3" stroke="#222222" />
                <XAxis dataKey="date" tick={{ fontSize: 10, fill: "#888780" }} tickFormatter={(v) => v.slice(5)} />
                <YAxis tick={{ fontSize: 10, fill: "#888780" }} />
                <Tooltip contentStyle={{ backgroundColor: "#111111", border: "1px solid #222222", borderRadius: 6, fontSize: 12 }} />
                <Line type="monotone" dataKey="count" name="Average" stroke="#1D9E75" strokeWidth={2} dot={{ r: 3, fill: "#1D9E75" }} />
                <Line type="monotone" dataKey="peak" name="Peak" stroke="#378ADD" strokeWidth={2} strokeDasharray="5 5" dot={{ r: 3, fill: "#378ADD" }} />
              </LineChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Resets Chart */}
        <div className="bg-[#111111] border border-[#222222] rounded-lg p-5">
          <h3 className="text-sm font-medium text-white mb-4">Resets per Day</h3>
          <div className="h-56">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={resetsPerDay}>
                <CartesianGrid strokeDasharray="3 3" stroke="#222222" />
                <XAxis dataKey="date" tick={{ fontSize: 10, fill: "#888780" }} tickFormatter={(v) => v.slice(5)} />
                <YAxis tick={{ fontSize: 10, fill: "#888780" }} />
                <Tooltip contentStyle={{ backgroundColor: "#111111", border: "1px solid #222222", borderRadius: 6, fontSize: 12 }} />
                <Bar dataKey="resets" fill="#7F77DD" radius={[4, 4, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>
      </div>

      {/* Top Players Table */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="bg-[#111111] border border-[#222222] rounded-lg overflow-hidden">
          <h3 className="text-sm font-medium text-white px-4 pt-4 pb-3">Top Players</h3>
          <table className="w-full text-xs">
            <thead>
              <tr className="border-b border-[#222222] text-[#888780]">
                <th className="text-left px-3 py-2 font-medium">#</th>
                <th className="text-left px-3 py-2 font-medium">Player</th>
                <th className="text-right px-3 py-2 font-medium">Level</th>
                <th className="text-right px-3 py-2 font-medium">Resets</th>
                <th className="text-right px-3 py-2 font-medium">VIP</th>
              </tr>
            </thead>
            <tbody>
              {topPlayers.map((p) => (
                <tr key={p.rank} className="border-b border-[#222222] last:border-0 hover:bg-[#1a1a1a]">
                  <td className="px-3 py-2 text-[#888780]">{p.rank}</td>
                  <td className="px-3 py-2 text-white font-medium">{p.name}</td>
                  <td className="px-3 py-2 text-right text-white">{p.level}</td>
                  <td className="px-3 py-2 text-right text-[#7F77DD]">{p.resets}</td>
                  <td className="px-3 py-2 text-right">
                    {p.vip ? (
                      <span className={`text-[10px] px-1.5 py-0.5 rounded ${
                        p.vip === "Ouro" ? "bg-[#EF9F27]/15 text-[#EF9F27]" :
                        p.vip === "Prata" ? "bg-[#888780]/15 text-[#888780]" :
                        "bg-[#D85A30]/15 text-[#D85A30]"
                      }`}>
                        {p.vip}
                      </span>
                    ) : <span className="text-[#888780]/30">—</span>}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        {/* Activity Heatmap */}
        <div className="bg-[#111111] border border-[#222222] rounded-lg p-5">
          <h3 className="text-sm font-medium text-white mb-4">Activity Heatmap</h3>
          <div className="overflow-x-auto">
            <div className="grid gap-1" style={{ gridTemplateColumns: `40px repeat(24, 1fr)` }}>
              {/* Hour Labels */}
              <div />
              {Array.from({ length: 24 }).map((_, h) => (
                <div key={h} className="text-[8px] text-[#888780]/60 text-center">{String(h).padStart(2, "0")}</div>
              ))}
              {/* Rows */}
              {heatmapData.map((row, dayIdx) => (
                <React.Fragment key={dayIdx}>
                  <div className="text-[10px] text-[#888780] flex items-center">{heatmapDays[dayIdx]}</div>
                  {row.map((val, hourIdx) => (
                    <div
                      key={`${dayIdx}-${hourIdx}`}
                      className="aspect-square rounded-sm"
                      style={{
                        backgroundColor: `rgba(29, 158, 117, ${Math.min(val / 65, 1) * 0.8 + 0.05})`,
                      }}
                      title={`${heatmapDays[dayIdx]} ${String(hourIdx).padStart(2, "00")}:00 — ${val} players`}
                    />
                  ))}
                </React.Fragment>
              ))}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
