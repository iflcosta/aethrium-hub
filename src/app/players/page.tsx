"use client";

import React from "react";
import { SectionHeader } from "@/components/section-header";
import { KpiCard } from "@/components/kpi-card";
import { Users, TrendingUp, UserCheck } from "lucide-react";

export default function PlayersPage() {
  return (
    <div>
      <SectionHeader title="Players" subtitle="Server population analytics" />

      {/* KPI Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 mb-6 opacity-50 grayscale">
        <KpiCard label="Online Now" value="—" icon={Users} accentColor="#1D9E75" />
        <KpiCard label="Peak Today" value="—" icon={TrendingUp} accentColor="#378ADD" />
        <KpiCard label="Total Accounts" value="—" icon={UserCheck} accentColor="#7F77DD" />
      </div>

      {/* Offline Placeholder */}
      <div className="bg-[#111111] border border-[#222222] rounded-lg p-12 flex flex-col items-center justify-center text-center space-y-4 mb-6 min-h-[400px]">
        <div className="w-12 h-12 rounded-full bg-blue-500/10 flex items-center justify-center">
          <Users className="text-blue-500 w-6 h-6 animate-pulse" />
        </div>
        <div>
          <h3 className="text-white font-medium">Aguardando servidor online</h3>
          <p className="text-xs text-[#888780] mt-1 max-w-xs">
            Estatísticas de players, recordes e atividade em tempo real serão exibidas assim que o servidor de jogo for conectado.
          </p>
        </div>
      </div>
    </div>
  );
}
