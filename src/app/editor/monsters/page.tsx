"use client";

import { useState, useMemo } from "react";
import { SectionHeader } from "@/components/section-header";
import { Search, Send, Plus, Trash2 } from "lucide-react";

interface Monster {
  id: number;
  name: string;
  health: number;
  exp: number;
  speed: number;
  summonable: boolean;
  convinceable: boolean;
  immunities: string[];
  loot: { item: string; chance: number }[];
  attacks: string[];
}

const initialMonsters: Monster[] = [
  { id: 1, name: "Demon Skeleton", health: 400, exp: 240, speed: 150, summonable: false, convinceable: false, immunities: ["fire", "poison"], loot: [{ item: "Skull", chance: 15 }, { item: "Demonic Essence", chance: 5 }], attacks: ["Melee", "Fire Wave"] },
  { id: 2, name: "Dragon Lord", health: 1900, exp: 2100, speed: 180, summonable: false, convinceable: false, immunities: ["fire"], loot: [{ item: "Golden Armor", chance: 1 }, { item: "Dragon Scale Mail", chance: 3 }, { item: "Fire Sword", chance: 2 }], attacks: ["Great Fireball", "Fire Wave", "Melee"] },
  { id: 3, name: "Hydra", health: 2350, exp: 2100, speed: 200, summonable: false, convinceable: false, immunities: ["earth"], loot: [{ item: "Hydra Head", chance: 10 }, { item: "Warrior Helmet", chance: 2 }], attacks: ["Earth Wave", "Poison Beam", "Melee"] },
  { id: 4, name: "Warlock", health: 3500, exp: 4000, speed: 160, summonable: false, convinceable: false, immunities: ["fire", "energy"], loot: [{ item: "Golden Armor", chance: 0.5 }, { item: "Skull Staff", chance: 1 }], attacks: ["Great Energy Beam", "Fire Wave", "Summon Fire Elemental"] },
  { id: 5, name: "Rotworm", health: 65, exp: 40, speed: 80, summonable: true, convinceable: true, immunities: [], loot: [{ item: "Meat", chance: 50 }, { item: "Worm", chance: 30 }], attacks: ["Melee"] },
  { id: 6, name: "Cyclops", health: 260, exp: 150, speed: 120, summonable: true, convinceable: true, immunities: [], loot: [{ item: "Cyclops Toe", chance: 8 }, { item: "Short Sword", chance: 12 }], attacks: ["Melee", "Stone Throw"] },
  { id: 7, name: "Giant Spider", health: 1300, exp: 900, speed: 140, summonable: false, convinceable: false, immunities: ["earth"], loot: [{ item: "Spider Silk", chance: 6 }, { item: "Plate Legs", chance: 3 }], attacks: ["Poison Beam", "Melee"] },
  { id: 8, name: "Lich", health: 880, exp: 900, speed: 155, summonable: false, convinceable: false, immunities: ["death", "ice"], loot: [{ item: "Mind Stone", chance: 4 }, { item: "Ring of Healing", chance: 2 }], attacks: ["Death Wave", "Lifedrain", "Melee"] },
];

const allImmunities = ["fire", "ice", "earth", "energy", "death", "poison", "holy", "physical"];

export default function MonsterEditorPage() {
  const [monsters, setMonsters] = useState(initialMonsters);
  const [search, setSearch] = useState("");
  const [selectedId, setSelectedId] = useState<number | null>(1);

  const filtered = useMemo(
    () => monsters.filter((m) => m.name.toLowerCase().includes(search.toLowerCase()) || String(m.id).includes(search)),
    [monsters, search]
  );

  const selected = monsters.find((m) => m.id === selectedId) || null;

  const update = (field: string, value: unknown) => {
    setMonsters((prev) => prev.map((m) => (m.id === selectedId ? { ...m, [field]: value } : m)));
  };

  const toggleImmunity = (imm: string) => {
    if (!selected) return;
    const next = selected.immunities.includes(imm)
      ? selected.immunities.filter((i) => i !== imm)
      : [...selected.immunities, imm];
    update("immunities", next);
  };

  const addLoot = () => {
    if (!selected) return;
    update("loot", [...selected.loot, { item: "New Item", chance: 10 }]);
  };

  const removeLoot = (idx: number) => {
    if (!selected) return;
    update("loot", selected.loot.filter((_, i) => i !== idx));
  };

  return (
    <div>
      <SectionHeader
        title="Monster Editor"
        subtitle="Edit monster data"
        action={
          <button className="flex items-center gap-1.5 text-xs px-3 py-1.5 rounded bg-[#7F77DD] text-white hover:bg-[#6b63cc] transition-colors">
            <Send className="w-3 h-3" /> Send to Beatriz
          </button>
        }
      />

      <div className="flex gap-4" style={{ height: "calc(100vh - 160px)" }}>
        {/* Left Panel */}
        <div className="w-96 shrink-0 bg-[#111111] border border-[#222222] rounded-lg overflow-hidden flex flex-col">
          <div className="p-3 border-b border-[#222222]">
            <div className="relative">
              <Search className="absolute left-2.5 top-1/2 -translate-y-1/2 w-3.5 h-3.5 text-[#888780]" />
              <input
                type="text"
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                placeholder="Search monsters..."
                className="w-full bg-[#0a0a0a] border border-[#222222] rounded pl-8 pr-3 py-1.5 text-xs text-white placeholder:text-[#888780]/40"
              />
            </div>
          </div>
          <div className="flex-1 overflow-y-auto">
            {/* Column Headers */}
            <div className="flex items-center px-3 py-1.5 text-[10px] text-[#888780] border-b border-[#222222] uppercase tracking-wider">
              <span className="flex-1">Name</span>
              <span className="w-16 text-right">HP</span>
              <span className="w-16 text-right">EXP</span>
            </div>
            {filtered.map((m) => (
              <div
                key={m.id}
                onClick={() => setSelectedId(m.id)}
                className={`flex items-center px-3 py-2 text-xs cursor-pointer border-b border-[#222222] transition-colors ${
                  m.id === selectedId ? "bg-[#1a1a1a]" : "hover:bg-[#1a1a1a]/50"
                }`}
              >
                <span className="flex-1 text-white truncate">{m.name}</span>
                <span className="w-16 text-right text-[#D85A30]">{m.health.toLocaleString()}</span>
                <span className="w-16 text-right text-[#1D9E75]">{m.exp.toLocaleString()}</span>
              </div>
            ))}
          </div>
        </div>

        {/* Right Panel */}
        {selected ? (
          <div className="flex-1 bg-[#111111] border border-[#222222] rounded-lg p-5 overflow-y-auto">
            <h3 className="text-lg font-semibold text-white mb-4">{selected.name}</h3>

            <div className="grid grid-cols-2 sm:grid-cols-4 gap-4 mb-6">
              <div>
                <label className="text-[10px] text-[#888780] uppercase tracking-wider mb-1 block">Name</label>
                <input value={selected.name} onChange={(e) => update("name", e.target.value)} className="w-full bg-[#0a0a0a] border border-[#222222] rounded px-3 py-1.5 text-sm text-white" />
              </div>
              <div>
                <label className="text-[10px] text-[#888780] uppercase tracking-wider mb-1 block">Health</label>
                <input type="number" value={selected.health} onChange={(e) => update("health", Number(e.target.value))} className="w-full bg-[#0a0a0a] border border-[#222222] rounded px-3 py-1.5 text-sm text-white" />
              </div>
              <div>
                <label className="text-[10px] text-[#888780] uppercase tracking-wider mb-1 block">Experience</label>
                <input type="number" value={selected.exp} onChange={(e) => update("exp", Number(e.target.value))} className="w-full bg-[#0a0a0a] border border-[#222222] rounded px-3 py-1.5 text-sm text-white" />
              </div>
              <div>
                <label className="text-[10px] text-[#888780] uppercase tracking-wider mb-1 block">Speed</label>
                <input type="number" value={selected.speed} onChange={(e) => update("speed", Number(e.target.value))} className="w-full bg-[#0a0a0a] border border-[#222222] rounded px-3 py-1.5 text-sm text-white" />
              </div>
            </div>

            {/* Toggles */}
            <div className="flex gap-6 mb-6">
              <label className="flex items-center gap-2 text-xs text-[#888780] cursor-pointer">
                <input type="checkbox" checked={selected.summonable} onChange={(e) => update("summonable", e.target.checked)} className="accent-[#7F77DD]" /> Summonable
              </label>
              <label className="flex items-center gap-2 text-xs text-[#888780] cursor-pointer">
                <input type="checkbox" checked={selected.convinceable} onChange={(e) => update("convinceable", e.target.checked)} className="accent-[#7F77DD]" /> Convinceable
              </label>
            </div>

            {/* Immunities */}
            <div className="mb-6">
              <p className="text-[10px] text-[#888780] uppercase tracking-wider mb-2">Immunities</p>
              <div className="flex flex-wrap gap-2">
                {allImmunities.map((imm) => (
                  <button
                    key={imm}
                    onClick={() => toggleImmunity(imm)}
                    className={`text-[11px] px-2 py-1 rounded border transition-colors ${
                      selected.immunities.includes(imm)
                        ? "bg-[#D85A30]/15 text-[#D85A30] border-[#D85A30]/30"
                        : "bg-[#1a1a1a] text-[#888780] border-[#222222] hover:border-[#333333]"
                    }`}
                  >
                    {imm}
                  </button>
                ))}
              </div>
            </div>

            {/* Loot Table */}
            <div className="mb-6">
              <div className="flex items-center justify-between mb-2">
                <p className="text-[10px] text-[#888780] uppercase tracking-wider">Loot Table</p>
                <button onClick={addLoot} className="flex items-center gap-1 text-[10px] text-[#888780] hover:text-white">
                  <Plus className="w-3 h-3" /> Add
                </button>
              </div>
              <div className="space-y-2">
                {selected.loot.map((l, i) => (
                  <div key={i} className="flex items-center gap-2">
                    <input
                      value={l.item}
                      onChange={(e) => {
                        const newLoot = [...selected.loot];
                        newLoot[i] = { ...newLoot[i], item: e.target.value };
                        update("loot", newLoot);
                      }}
                      className="flex-1 bg-[#0a0a0a] border border-[#222222] rounded px-2 py-1 text-xs text-white"
                    />
                    <input
                      type="number"
                      value={l.chance}
                      onChange={(e) => {
                        const newLoot = [...selected.loot];
                        newLoot[i] = { ...newLoot[i], chance: Number(e.target.value) };
                        update("loot", newLoot);
                      }}
                      className="w-16 bg-[#0a0a0a] border border-[#222222] rounded px-2 py-1 text-xs text-white text-right"
                    />
                    <span className="text-[10px] text-[#888780]">%</span>
                    <button onClick={() => removeLoot(i)} className="text-[#888780] hover:text-[#D85A30]">
                      <Trash2 className="w-3 h-3" />
                    </button>
                  </div>
                ))}
              </div>
            </div>

            {/* Attacks */}
            <div>
              <p className="text-[10px] text-[#888780] uppercase tracking-wider mb-2">Attack Spells</p>
              <div className="flex flex-wrap gap-2">
                {selected.attacks.map((atk) => (
                  <span key={atk} className="text-[11px] px-2 py-1 rounded bg-[#EF9F27]/15 text-[#EF9F27] border border-[#EF9F27]/20">
                    {atk}
                  </span>
                ))}
              </div>
            </div>
          </div>
        ) : (
          <div className="flex-1 bg-[#111111] border border-[#222222] rounded-lg flex items-center justify-center text-sm text-[#888780]">
            Select a monster to edit
          </div>
        )}
      </div>
    </div>
  );
}
