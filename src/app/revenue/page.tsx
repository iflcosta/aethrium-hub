"use client";

import { SectionHeader } from "@/components/section-header";
import { KpiCard } from "@/components/kpi-card";
import { DollarSign, TrendingUp, Target } from "lucide-react";

export default function RevenuePage() {
  return (
    <div>
      <SectionHeader title="Revenue" subtitle="Monetization analytics" />

      {/* KPI Row */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 mb-6 opacity-50 grayscale">
        <KpiCard label="Current Month" value="R$ —" icon={DollarSign} accentColor="#EF9F27" />
        <KpiCard label="Goal" value="R$ —" icon={Target} accentColor="#1D9E75" />
        <KpiCard label="Pessimist Threshold" value="R$ —" icon={TrendingUp} accentColor="#D85A30" />
      </div>

      {/* Offline Placeholder */}
      <div className="bg-[#111111] border border-[#222222] rounded-lg p-12 flex flex-col items-center justify-center text-center space-y-4 mb-6">
        <div className="w-12 h-12 rounded-full bg-amber-500/10 flex items-center justify-center">
          <TrendingUp className="text-amber-500 w-6 h-6 animate-pulse" />
        </div>
        <div>
          <h3 className="text-white font-medium">Aguardando servidor online</h3>
          <p className="text-xs text-[#888780] mt-1 max-w-xs">
            As métricas de faturamento e transações serão exibidas automaticamente assim que o servidor do jogo estiver ativo.
          </p>
        </div>
      </div>
    </div>
  );
}
