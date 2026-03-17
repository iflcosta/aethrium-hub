export interface PlayerOnline {
  date: string;
  count: number;
  peak: number;
}

export const playersOnline7d: PlayerOnline[] = [
  { date: "2026-03-09", count: 42, peak: 58 },
  { date: "2026-03-10", count: 48, peak: 63 },
  { date: "2026-03-11", count: 39, peak: 55 },
  { date: "2026-03-12", count: 51, peak: 67 },
  { date: "2026-03-13", count: 45, peak: 61 },
  { date: "2026-03-14", count: 53, peak: 72 },
  { date: "2026-03-15", count: 24, peak: 67 },
];

export const resetsPerDay = [
  { date: "2026-03-09", resets: 3 },
  { date: "2026-03-10", resets: 5 },
  { date: "2026-03-11", resets: 2 },
  { date: "2026-03-12", resets: 7 },
  { date: "2026-03-13", resets: 4 },
  { date: "2026-03-14", resets: 6 },
  { date: "2026-03-15", resets: 3 },
];

export interface TopPlayer {
  rank: number;
  name: string;
  level: number;
  resets: number;
  vip: "Ouro" | "Prata" | "Bronze" | null;
  guild: string;
}

export const topPlayers: TopPlayer[] = [
  { rank: 1, name: "DragonSlayer99", level: 987, resets: 12, vip: "Ouro", guild: "Phoenix Order" },
  { rank: 2, name: "NightElf", level: 964, resets: 11, vip: "Ouro", guild: "Shadow Realm" },
  { rank: 3, name: "BladeMaster", level: 951, resets: 10, vip: "Prata", guild: "Iron Legion" },
  { rank: 4, name: "ArcaneWiz", level: 938, resets: 10, vip: "Ouro", guild: "Mystic Circle" },
  { rank: 5, name: "ThunderAxe", level: 912, resets: 9, vip: "Prata", guild: "Phoenix Order" },
  { rank: 6, name: "FrostHunter", level: 889, resets: 8, vip: "Bronze", guild: "Frost Clan" },
  { rank: 7, name: "ShadowMage", level: 876, resets: 8, vip: null, guild: "Shadow Realm" },
  { rank: 8, name: "IronFist", level: 852, resets: 7, vip: "Bronze", guild: "Iron Legion" },
  { rank: 9, name: "LunarWitch", level: 834, resets: 7, vip: "Prata", guild: "Mystic Circle" },
  { rank: 10, name: "PixelKnight", level: 821, resets: 6, vip: null, guild: "Pixel Warriors" },
];

// Heatmap: 7 days × 24 hours, values 0-100 representing player activity intensity
export const heatmapData: number[][] = [
  [5,3,2,1,1,2,4,12,25,38,42,45,48,50,47,44,40,35,30,28,22,15,10,7],
  [6,4,2,1,1,3,5,15,28,40,45,48,51,53,50,46,42,38,33,30,24,17,12,8],
  [4,3,2,1,1,2,4,10,22,35,39,42,44,46,43,40,36,32,27,24,19,13,9,6],
  [7,5,3,2,1,3,6,18,32,45,50,54,57,59,55,50,46,41,36,33,27,20,14,9],
  [5,4,2,1,1,2,5,14,27,41,46,49,52,54,51,47,43,38,34,30,25,18,12,8],
  [8,6,4,2,2,4,7,20,35,50,56,60,63,65,61,56,52,46,40,36,30,22,16,10],
  [6,4,3,2,1,3,5,16,30,44,48,52,55,57,53,49,45,40,35,31,26,19,13,8],
];

export const heatmapDays = ["Dom", "Seg", "Ter", "Qua", "Qui", "Sex", "Sáb"];

export const playerStats = {
  onlineNow: 24,
  peakToday: 67,
  totalAccounts: 340,
};
