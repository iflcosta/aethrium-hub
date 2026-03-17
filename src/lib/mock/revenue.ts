export interface DailyRevenue {
  date: string;
  vip: number;
  stamina: number;
  stones: number;
  total: number;
}

function generateRevenueData(): DailyRevenue[] {
  const data: DailyRevenue[] = [];
  const now = new Date("2026-03-15");
  for (let i = 29; i >= 0; i--) {
    const d = new Date(now);
    d.setDate(d.getDate() - i);
    const vip = Math.round(15 + Math.random() * 35);
    const stamina = Math.round(10 + Math.random() * 30);
    const stones = Math.round(20 + Math.random() * 50);
    data.push({
      date: d.toISOString().slice(0, 10),
      vip,
      stamina,
      stones,
      total: vip + stamina + stones,
    });
  }
  return data;
}

export const revenueData = generateRevenueData();

export const revenueGoal = 3000;
export const revenueCurrent = 1240;
export const revenuePessimist = 885;

export const systemRevenue = [
  { name: "Dodge/Critical/Reflect", current: 480, range: "R$300–3.000/mês", color: "#D85A30" },
  { name: "VIP System", current: 420, range: "R$190–1.875/mês", color: "#EF9F27" },
  { name: "Stamina Refill", current: 340, range: "R$250–1.800/mês", color: "#1D9E75" },
];

export interface Transaction {
  id: string;
  player: string;
  system: string;
  item: string;
  amount: number;
  date: string;
}

export const recentTransactions: Transaction[] = [
  { id: "tx1", player: "DragonSlayer99", system: "Stones", item: "Epic Dodge Stone", amount: 50, date: "2026-03-15T17:42:00Z" },
  { id: "tx2", player: "NightElf", system: "VIP", item: "VIP Ouro", amount: 40, date: "2026-03-15T17:30:00Z" },
  { id: "tx3", player: "PixelKnight", system: "Stamina", item: "Infinite 7d", amount: 50, date: "2026-03-15T16:55:00Z" },
  { id: "tx4", player: "ShadowMage", system: "Stones", item: "Critical Stone", amount: 30, date: "2026-03-15T16:20:00Z" },
  { id: "tx5", player: "IronFist", system: "VIP", item: "VIP Prata", amount: 25, date: "2026-03-15T15:45:00Z" },
  { id: "tx6", player: "LunarWitch", system: "Stamina", item: "Refill 42h", amount: 25, date: "2026-03-15T15:10:00Z" },
  { id: "tx7", player: "BladeMaster", system: "Stones", item: "Reflect Stone", amount: 35, date: "2026-03-15T14:30:00Z" },
  { id: "tx8", player: "ArcaneWiz", system: "VIP", item: "VIP Bronze", amount: 15, date: "2026-03-15T14:00:00Z" },
  { id: "tx9", player: "ThunderAxe", system: "Stamina", item: "Refill 3h", amount: 10, date: "2026-03-15T13:20:00Z" },
  { id: "tx10", player: "FrostHunter", system: "Stones", item: "Dodge Stone", amount: 20, date: "2026-03-15T12:45:00Z" },
];
