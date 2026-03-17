import { SectionHeader } from "@/components/section-header";

export default function SettingsPage() {
  return (
    <div>
      <SectionHeader title="Settings" subtitle="Application configuration" />

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* General */}
        <div className="bg-[#111111] border border-[#222222] rounded-lg p-5">
          <h3 className="text-sm font-medium text-white mb-4">General</h3>
          <div className="space-y-4">
            <div>
              <label className="text-[10px] text-[#888780] uppercase tracking-wider mb-1 block">Server Name</label>
              <input
                defaultValue="Aethrium OTServ"
                className="w-full bg-[#0a0a0a] border border-[#222222] rounded px-3 py-1.5 text-sm text-white"
              />
            </div>
            <div>
              <label className="text-[10px] text-[#888780] uppercase tracking-wider mb-1 block">Server Version</label>
              <input
                defaultValue="1.4.0"
                className="w-full bg-[#0a0a0a] border border-[#222222] rounded px-3 py-1.5 text-sm text-white"
              />
            </div>
            <div>
              <label className="text-[10px] text-[#888780] uppercase tracking-wider mb-1 block">Max Players</label>
              <input
                type="number"
                defaultValue={500}
                className="w-full bg-[#0a0a0a] border border-[#222222] rounded px-3 py-1.5 text-sm text-white"
              />
            </div>
          </div>
        </div>

        {/* API Keys */}
        <div className="bg-[#111111] border border-[#222222] rounded-lg p-5">
          <h3 className="text-sm font-medium text-white mb-4">API Configuration</h3>
          <div className="space-y-4">
            <div>
              <label className="text-[10px] text-[#888780] uppercase tracking-wider mb-1 block">OpenAI API Key</label>
              <input
                type="password"
                defaultValue="sk-..."
                className="w-full bg-[#0a0a0a] border border-[#222222] rounded px-3 py-1.5 text-sm text-white"
              />
            </div>
            <div>
              <label className="text-[10px] text-[#888780] uppercase tracking-wider mb-1 block">Default Model</label>
              <select className="w-full bg-[#0a0a0a] border border-[#222222] rounded px-3 py-1.5 text-sm text-white">
                <option>gpt-4o</option>
                <option>claude-sonnet</option>
                <option>gemini-pro</option>
              </select>
            </div>
            <div>
              <label className="text-[10px] text-[#888780] uppercase tracking-wider mb-1 block">Supabase URL</label>
              <input
                defaultValue="https://wpoqimsahieymjcrxgdj.supabase.co"
                className="w-full bg-[#0a0a0a] border border-[#222222] rounded px-3 py-1.5 text-sm text-white"
              />
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
