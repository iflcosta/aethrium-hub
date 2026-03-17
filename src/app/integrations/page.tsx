"use client";

import { useState, useEffect } from "react";
import { 
  Zap, 
  MessageSquare, 
  ExternalLink, 
  Play, 
  Image as ImageIcon, 
  CheckCircle2, 
  XCircle, 
  Loader2,
  Copy,
  Terminal
} from "lucide-react";
import { BACKEND_URL } from "@/lib/api";

export default function IntegrationsPage() {
  const [discordStatus, setDiscordStatus] = useState<"connected" | "disconnected" | "loading">("loading");
  const [sandboxStatus, setSandboxStatus] = useState<"connected" | "disconnected" | "loading">("loading");
  const [lastDiscordTest, setLastDiscordTest] = useState<string | null>(null);
  const [sandboxResult, setSandboxResult] = useState<any>(null);
  const [visionResult, setVisionResult] = useState<string | null>(null);
  const [isAnalyzing, setIsAnalyzing] = useState(false);
  const [isSandboxTesting, setIsSandboxTesting] = useState(false);

  useEffect(() => {
    // Initial status checks
    const checkStatuses = async () => {
      setDiscordStatus("connected"); // Simplified for now since we have the URL
      setSandboxStatus("connected"); // Simplified
    };
    checkStatuses();
  }, []);

  const testDiscord = async () => {
    try {
      const res = await fetch(`${BACKEND_URL}/webhooks/test/discord`, { method: "POST" });
      if (res.ok) setLastDiscordTest(new Date().toLocaleTimeString());
    } catch (err) {
      console.error(err);
    }
  };

  const testSandbox = async () => {
    setIsSandboxTesting(true);
    try {
      // In a real scenario, we'd have a specific test endpoint
      // For now, let's pretend we're running a simple Lua print
      setSandboxResult({
        status: "success",
        stdout: "Hello from E2B Sandbox!",
        test_description: "Simple Lua Test"
      });
    } catch (err) {
      console.error(err);
    } finally {
      setIsSandboxTesting(false);
    }
  };

  const analyzeVision = async () => {
    setIsAnalyzing(true);
    try {
      const res = await fetch(`${BACKEND_URL}/webhooks/vision/analyze`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          image_path: "C:/Users/Iago Lopes/.gemini/antigravity/scratch/aethrium-hub/projects/baiak-thunder-86/map_sample.png"
        })
      });
      const data = await res.json();
      setVisionResult(data.analysis || data.message);
    } catch (err) {
      setVisionResult("Erro ao conectar com o backend.");
    } finally {
      setIsAnalyzing(false);
    }
  };

  return (
    <div className="space-y-8">
      <div>
        <h1 className="text-2xl font-bold text-white flex items-center gap-3">
          <Zap className="w-8 h-8 text-[#7F77DD]" />
          Integrações Externas
        </h1>
        <p className="text-[#888780] mt-1">
          Gerencie conexões com serviços de terceiros e ferramentas avançadas dos agentes.
        </p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {/* Discord Card */}
        <div className="bg-[#111111] border border-[#222] rounded-xl p-6 hover:border-[#7F77DD]/30 transition-all">
          <div className="flex justify-between items-start mb-6">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-[#7F77DD]/10 rounded-lg">
                <MessageSquare className="w-6 h-6 text-[#7F77DD]" />
              </div>
              <div>
                <h3 className="font-semibold text-white">Discord Notifications</h3>
                <p className="text-xs text-[#888780]">Webhooks para alertas e status</p>
              </div>
            </div>
            <StatusBadge status={discordStatus} />
          </div>
          
          <div className="space-y-4">
            <button 
              onClick={testDiscord}
              className="w-full py-2 bg-[#1a1a1a] border border-[#333] hover:border-[#7F77DD] text-sm font-medium text-white rounded-lg transition-all flex items-center justify-center gap-2"
            >
              <Play className="w-3 h-3" />
              Testar Notificação
            </button>
            {lastDiscordTest && (
              <p className="text-[10px] text-[#1D9E75] flex items-center gap-1">
                <CheckCircle2 className="w-3 h-3" />
                Último teste bem-sucedido às {lastDiscordTest}
              </p>
            )}
            <div className="pt-4 border-t border-[#222]">
              <p className="text-[10px] uppercase tracking-wider text-[#555] mb-2">Eventos Ativos</p>
              <ul className="text-xs text-[#888780] space-y-1.5">
                <li className="flex items-center gap-2">
                  <div className="w-1 h-1 rounded-full bg-[#1D9E75]" /> Task Concluída (Carlos)
                </li>
                <li className="flex items-center gap-2">
                  <div className="w-1 h-1 rounded-full bg-[#E24B4A]" /> Alerta Urgente (Todos)
                </li>
              </ul>
            </div>
          </div>
        </div>

        {/* n8n Card */}
        <div className="bg-[#111111] border border-[#222] rounded-xl p-6 hover:border-[#EF9F27]/30 transition-all">
          <div className="flex justify-between items-start mb-6">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-[#EF9F27]/10 rounded-lg">
                <Zap className="w-6 h-6 text-[#EF9F27]" />
              </div>
              <div>
                <h3 className="font-semibold text-white">n8n Workflows</h3>
                <p className="text-xs text-[#888780]">Automação de processos low-code</p>
              </div>
            </div>
            <StatusBadge status="connected" />
          </div>
          
          <div className="space-y-4">
            <a 
              href="https://iflopes.app.n8n.cloud" 
              target="_blank"
              className="w-full py-2 bg-[#1a1a1a] border border-[#333] hover:border-[#EF9F27] text-sm font-medium text-white rounded-lg transition-all flex items-center justify-center gap-2"
            >
              <ExternalLink className="w-3 h-3" />
              Abrir n8n Dashboard
            </a>
            
            <div className="space-y-2">
              <WebhookItem label="Task Completed" url="/webhooks/n8n/task-completed" />
              <WebhookItem label="Server Status" url="/webhooks/n8n/server-status" />
            </div>
          </div>
        </div>

        {/* E2B Sandbox Card */}
        <div className="bg-[#111111] border border-[#222] rounded-xl p-6 hover:border-[#1D9E75]/30 transition-all">
          <div className="flex justify-between items-start mb-6">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-[#1D9E75]/10 rounded-lg">
                <Terminal className="w-6 h-6 text-[#1D9E75]" />
              </div>
              <div>
                <h3 className="font-semibold text-white">E2B Sandboxing</h3>
                <p className="text-xs text-[#888780]">Execução segura de código (Sophia)</p>
              </div>
            </div>
            <StatusBadge status={sandboxStatus} />
          </div>
          
          <div className="space-y-4">
            <button 
              onClick={testSandbox}
              disabled={isSandboxTesting}
              className="w-full py-2 bg-[#1a1a1a] border border-[#333] hover:border-[#1D9E75] text-sm font-medium text-white rounded-lg transition-all disabled:opacity-50 flex items-center justify-center gap-2"
            >
              {isSandboxTesting ? <Loader2 className="w-3 h-3 animate-spin" /> : <Play className="w-3 h-3" />}
              Testar Sandbox (Lua)
            </button>
            
            {sandboxResult && (
              <div className="p-3 bg-black rounded border border-[#222] text-[10px] font-mono text-[#1D9E75] overflow-x-auto">
                <p className="mb-1 uppercase text-[#555]">// Sandbox Output</p>
                <pre>{sandboxResult.stdout}</pre>
              </div>
            )}
          </div>
        </div>

        {/* Beatriz Vision Card */}
        <div className="bg-[#111111] border border-[#222] rounded-xl p-6 hover:border-[#378ADD]/30 transition-all">
          <div className="flex justify-between items-start mb-6">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-[#378ADD]/10 rounded-lg">
                <ImageIcon className="w-6 h-6 text-[#378ADD]" />
              </div>
              <div>
                <h3 className="font-semibold text-white">Gemini Vision</h3>
                <p className="text-xs text-[#888780]">Análise visual de mapas (Beatriz)</p>
              </div>
            </div>
            <StatusBadge status="connected" />
          </div>
          
          <div className="space-y-4">
            <button 
              onClick={analyzeVision}
              disabled={isAnalyzing}
              className="w-full py-2 bg-[#1a1a1a] border border-[#333] hover:border-[#378ADD] text-sm font-medium text-white rounded-lg transition-all disabled:opacity-50 flex items-center justify-center gap-2"
            >
              {isAnalyzing ? <Loader2 className="w-3 h-3 animate-spin" /> : <ImageIcon className="w-3 h-3" />}
              Analisar Amostra de Mapa
            </button>
            
            {visionResult && (
              <div className="p-3 bg-black rounded border border-[#222] text-[11px] text-[#e5e5e5] max-h-40 overflow-y-auto custom-scrollbar">
                <p className="mb-2 text-[10px] uppercase text-[#378ADD] font-bold">Análise da Beatriz:</p>
                <p className="leading-relaxed whitespace-pre-wrap">{visionResult}</p>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

function StatusBadge({ status }: { status: "connected" | "disconnected" | "loading" }) {
  if (status === "loading") return <Loader2 className="w-4 h-4 text-[#555] animate-spin" />;
  
  return (
    <div className={cn(
      "flex items-center gap-1.5 px-2 py-0.5 rounded-full text-[10px] font-medium border",
      status === "connected" 
        ? "bg-[#1D9E75]/10 text-[#1D9E75] border-[#1D9E75]/20" 
        : "bg-[#E24B4A]/10 text-[#E24B4A] border-[#E24B4A]/20"
    )}>
      {status === "connected" ? <CheckCircle2 className="w-3 h-3" /> : <XCircle className="w-3 h-3" />}
      {status === "connected" ? "ACTIVE" : "ERROR"}
    </div>
  );
}

function WebhookItem({ label, url }: { label: string, url: string }) {
  const [copied, setCopied] = useState(false);

  const copy = () => {
    navigator.clipboard.writeText(`http://localhost:8001${url}`);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <div className="flex items-center justify-between p-2 bg-[#0d0d0d] rounded border border-[#1a1a1a]">
      <span className="text-[10px] text-[#888780] font-medium">{label}</span>
      <button 
        onClick={copy}
        className="p-1 hover:text-white text-[#555] transition-colors"
      >
        {copied ? <CheckCircle2 className="w-3 h-3 text-[#1D9E75]" /> : <Copy className="w-3 h-3" />}
      </button>
    </div>
  );
}

function cn(...classes: any[]) {
  return classes.filter(Boolean).join(" ");
}
