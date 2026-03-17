"use client";

import { SectionHeader } from "@/components/section-header";
import { KpiCard } from "@/components/kpi-card";
import { revenueData, revenueCurrent, revenueGoal, revenuePessimist, systemRevenue, recentTransactions } from "@/lib/mock/revenue";
import { DollarSign, TrendingUp, Target } from "lucide-react";
import {
  LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip,
  ResponsiveContainer, Area, AreaChart, Legend,
  ReferenceLine,
} from "recharts";

export default function RevenuePage() {
  const progressPct = Math.round((revenueCurrent / revenueGoal) * 100);

  return (
    <div>
      <SectionHeader title="Revenue" subtitle="Monetization analytics" />

      {/* KPI Row */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 mb-6">
        <KpiCard label="Current Month" value={`R$ ${revenueCurrent.toLocaleString()}`} trend="+12%" trendUp icon={DollarSign} accentColor="#EF9F27" />
        <KpiCard label="Goal" value={`R$ ${revenueGoal.toLocaleString()}`} icon={Target} accentColor="#1D9E75" progress={progressPct} />
        <KpiCard label="Pessimist Threshold" value={`R$ ${revenuePessimist}`} icon={TrendingUp} accentColor="#D85A30" />
      </div>

      {/* Revenue Chart */}
      <div className="bg-[#111111] border border-[#222222] rounded-lg p-5 mb-6">
        <h3 className="text-sm font-medium text-white mb-4">Revenue — Last 30 Days</h3>
        <div className="h-72">
          <ResponsiveContainer width="100%" height="100%">
            <AreaChart data={revenueData}>
              <defs>
                <linearGradient id="gVip" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#EF9F27" stopOpacity={0.3} />
                  <stop offset="95%" stopColor="#EF9F27" stopOpacity={0} />
                </linearGradient>
                <linearGradient id="gStamina" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#1D9E75" stopOpacity={0.3} />
                  <stop offset="95%" stopColor="#1D9E75" stopOpacity={0} />
                </linearGradient>
                <linearGradient id="gStones" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#D85A30" stopOpacity={0.3} />
                  <stop offset="95%" stopColor="#D85A30" stopOpacity={0} />
                </linearGradient>
              </defs>
              <CartesianGrid strokeDasharray="3 3" stroke="#222222" />
              <XAxis dataKey="date" tick={{ fontSize: 10, fill: "#888780" }} tickFormatter={(v) => v.slice(5)} />
              <YAxis tick={{ fontSize: 10, fill: "#888780" }} />
              <Tooltip
                contentStyle={{ backgroundColor: "#111111", border: "1px solid #222222", borderRadius: 6, fontSize: 12 }}
                labelStyle={{ color: "#888780" }}
              />
              <Legend wrapperStyle={{ fontSize: 11 }} />
              <Area type="monotone" dataKey="vip" name="VIP" stroke="#EF9F27" fill="url(#gVip)" strokeWidth={2} />
              <Area type="monotone" dataKey="stamina" name="Stamina" stroke="#1D9E75" fill="url(#gStamina)" strokeWidth={2} />
              <Area type="monotone" dataKey="stones" name="Stones" stroke="#D85A30" fill="url(#gStones)" strokeWidth={2} />
            </AreaChart>
          </ResponsiveContainer>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* System Revenue Cards */}
        <div>
          <h3 className="text-sm font-medium text-white mb-3">Revenue by System</h3>
          <div className="space-y-3">
            {systemRevenue.map((s) => (
              <div key={s.name} className="bg-[#111111] border border-[#222222] rounded-lg p-4">
                <div className="flex items-center justify-between mb-2">
                  <span className="text-sm text-white font-medium">{s.name}</span>
                  <span className="text-sm font-semibold text-white">R$ {s.current}</span>
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-xs text-[#888780]">{s.range}</span>
                  <div className="w-24 h-1.5 bg-[#1a1a1a] rounded-full overflow-hidden">
                    <div
                      className="h-full rounded-full"
                      style={{ width: `${(s.current / 500) * 100}%`, backgroundColor: s.color }}
                    />
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Transactions Table */}
        <div>
          <h3 className="text-sm font-medium text-white mb-3">Recent Transactions</h3>
          <div className="bg-[#111111] border border-[#222222] rounded-lg overflow-hidden">
            <table className="w-full text-xs">
              <thead>
                <tr className="border-b border-[#222222] text-[#888780]">
                  <th className="text-left px-3 py-2 font-medium">Player</th>
                  <th className="text-left px-3 py-2 font-medium">Item</th>
                  <th className="text-right px-3 py-2 font-medium">Amount</th>
                </tr>
              </thead>
              <tbody>
                {recentTransactions.map((tx) => (
                  <tr key={tx.id} className="border-b border-[#222222] last:border-0 hover:bg-[#1a1a1a]">
                    <td className="px-3 py-2 text-white">{tx.player}</td>
                    <td className="px-3 py-2 text-[#888780]">{tx.item}</td>
                    <td className="px-3 py-2 text-right text-[#EF9F27] font-medium">R$ {tx.amount}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  );
}
