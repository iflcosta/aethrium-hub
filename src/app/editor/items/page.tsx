"use client";

import { useState, useMemo } from "react";
import { SectionHeader } from "@/components/section-header";
import { mockItems, type MockItem } from "@/lib/mock/items";
import { Search, Save, Send } from "lucide-react";

export default function ItemEditorPage() {
  const [items, setItems] = useState<MockItem[]>(mockItems);
  const [search, setSearch] = useState("");
  const [selectedId, setSelectedId] = useState<number | null>(mockItems[0]?.id || null);

  const filtered = useMemo(
    () =>
      items.filter(
        (it) =>
          it.name.toLowerCase().includes(search.toLowerCase()) ||
          String(it.id).includes(search)
      ),
    [items, search]
  );

  const selected = items.find((it) => it.id === selectedId) || null;

  const updateField = (field: string, value: unknown) => {
    setItems((prev) =>
      prev.map((it) => (it.id === selectedId ? { ...it, [field]: value } : it))
    );
  };

  const updateFlag = (flag: string, value: boolean) => {
    setItems((prev) =>
      prev.map((it) =>
        it.id === selectedId ? { ...it, flags: { ...it.flags, [flag]: value } } : it
      )
    );
  };

  const handleSave = () => {
    const blob = new Blob([JSON.stringify(items, null, 2)], { type: "application/json" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = "items.json";
    a.click();
    URL.revokeObjectURL(url);
  };

  const typeBadgeColor: Record<string, string> = {
    sword: "#D85A30", axe: "#D85A30", shield: "#378ADD", armor: "#378ADD",
    helmet: "#378ADD", legs: "#378ADD", boots: "#378ADD", amulet: "#7F77DD",
    ring: "#7F77DD", potion: "#1D9E75", rune: "#EF9F27", misc: "#888780",
  };

  return (
    <div>
      <SectionHeader
        title="Item Editor"
        subtitle="Edit items.json data"
        action={
          <div className="flex gap-2">
            <button onClick={handleSave} className="flex items-center gap-1.5 text-xs px-3 py-1.5 rounded bg-[#1D9E75] text-white hover:bg-[#178a64] transition-colors">
              <Save className="w-3 h-3" /> Save
            </button>
            <button className="flex items-center gap-1.5 text-xs px-3 py-1.5 rounded bg-[#7F77DD] text-white hover:bg-[#6b63cc] transition-colors">
              <Send className="w-3 h-3" /> Send to Beatriz
            </button>
          </div>
        }
      />

      <div className="flex gap-4" style={{ height: "calc(100vh - 160px)" }}>
        {/* Left Panel - Item List */}
        <div className="w-96 shrink-0 bg-[#111111] border border-[#222222] rounded-lg overflow-hidden flex flex-col">
          {/* Search */}
          <div className="p-3 border-b border-[#222222]">
            <div className="relative">
              <Search className="absolute left-2.5 top-1/2 -translate-y-1/2 w-3.5 h-3.5 text-[#888780]" />
              <input
                type="text"
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                placeholder="Search ID or name..."
                className="w-full bg-[#0a0a0a] border border-[#222222] rounded pl-8 pr-3 py-1.5 text-xs text-white placeholder:text-[#888780]/40"
              />
            </div>
          </div>

          {/* Item List */}
          <div className="flex-1 overflow-y-auto">
            {filtered.map((item) => (
              <div
                key={item.id}
                onClick={() => setSelectedId(item.id)}
                className={`flex items-center gap-2.5 px-3 py-2 cursor-pointer border-b border-[#222222] text-xs transition-colors ${
                  item.id === selectedId ? "bg-[#1a1a1a]" : "hover:bg-[#1a1a1a]/50"
                }`}
              >
                {/* Sprite Placeholder */}
                <div className="w-8 h-8 bg-[#1a1a1a] border border-[#222222] rounded flex items-center justify-center text-[8px] text-[#888780] font-mono shrink-0">
                  {item.id}
                </div>
                <div className="flex-1 min-w-0">
                  <div className="text-white truncate">{item.name}</div>
                  <span className="text-[10px] px-1 py-0.5 rounded" style={{ backgroundColor: (typeBadgeColor[item.type] || "#888780") + "20", color: typeBadgeColor[item.type] || "#888780" }}>
                    {item.type}
                  </span>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Right Panel - Editor */}
        {selected ? (
          <div className="flex-1 bg-[#111111] border border-[#222222] rounded-lg p-5 overflow-y-auto">
            {/* Sprite Preview */}
            <div className="flex items-start gap-4 mb-6">
              <div className="w-16 h-16 bg-[#1a1a1a] border border-[#222222] rounded-lg flex items-center justify-center text-sm text-[#888780] font-mono shrink-0">
                {selected.id}
              </div>
              <div>
                <h3 className="text-lg font-semibold text-white">{selected.name}</h3>
                <p className="text-xs text-[#888780]">ID: {selected.id} · Type: {selected.type}</p>
              </div>
            </div>

            {/* Fields */}
            <div className="grid grid-cols-2 gap-4 mb-6">
              <div>
                <label className="text-[10px] text-[#888780] uppercase tracking-wider mb-1 block">Name</label>
                <input
                  value={selected.name}
                  onChange={(e) => updateField("name", e.target.value)}
                  className="w-full bg-[#0a0a0a] border border-[#222222] rounded px-3 py-1.5 text-sm text-white"
                />
              </div>
              <div>
                <label className="text-[10px] text-[#888780] uppercase tracking-wider mb-1 block">Weight</label>
                <input
                  type="number"
                  value={selected.weight}
                  onChange={(e) => updateField("weight", Number(e.target.value))}
                  className="w-full bg-[#0a0a0a] border border-[#222222] rounded px-3 py-1.5 text-sm text-white"
                />
              </div>
              {selected.attack !== undefined && (
                <div>
                  <label className="text-[10px] text-[#888780] uppercase tracking-wider mb-1 block">Attack</label>
                  <input
                    type="number"
                    value={selected.attack}
                    onChange={(e) => updateField("attack", Number(e.target.value))}
                    className="w-full bg-[#0a0a0a] border border-[#222222] rounded px-3 py-1.5 text-sm text-white"
                  />
                </div>
              )}
              {selected.defense !== undefined && (
                <div>
                  <label className="text-[10px] text-[#888780] uppercase tracking-wider mb-1 block">Defense</label>
                  <input
                    type="number"
                    value={selected.defense}
                    onChange={(e) => updateField("defense", Number(e.target.value))}
                    className="w-full bg-[#0a0a0a] border border-[#222222] rounded px-3 py-1.5 text-sm text-white"
                  />
                </div>
              )}
              {selected.armor !== undefined && (
                <div>
                  <label className="text-[10px] text-[#888780] uppercase tracking-wider mb-1 block">Armor</label>
                  <input
                    type="number"
                    value={selected.armor}
                    onChange={(e) => updateField("armor", Number(e.target.value))}
                    className="w-full bg-[#0a0a0a] border border-[#222222] rounded px-3 py-1.5 text-sm text-white"
                  />
                </div>
              )}
            </div>

            <div className="mb-6">
              <label className="text-[10px] text-[#888780] uppercase tracking-wider mb-1 block">Description</label>
              <textarea
                value={selected.description}
                onChange={(e) => updateField("description", e.target.value)}
                className="w-full bg-[#0a0a0a] border border-[#222222] rounded px-3 py-2 text-sm text-white h-20 resize-none"
              />
            </div>

            {/* Flags */}
            <div>
              <p className="text-[10px] text-[#888780] uppercase tracking-wider mb-2">Flags</p>
              <div className="grid grid-cols-2 sm:grid-cols-3 gap-2">
                {Object.entries(selected.flags).map(([key, val]) => (
                  <label
                    key={key}
                    className="flex items-center gap-2 text-xs text-[#888780] cursor-pointer hover:text-white"
                  >
                    <input
                      type="checkbox"
                      checked={val}
                      onChange={(e) => updateFlag(key, e.target.checked)}
                      className="accent-[#7F77DD] w-3.5 h-3.5"
                    />
                    {key}
                  </label>
                ))}
              </div>
            </div>
          </div>
        ) : (
          <div className="flex-1 bg-[#111111] border border-[#222222] rounded-lg flex items-center justify-center text-sm text-[#888780]">
            Select an item to edit
          </div>
        )}
      </div>
    </div>
  );
}
