export type LogType = "LOGIN" | "LOGOUT" | "COMBAT" | "TRADE" | "VIP" | "RESET" | "SYSTEM";

export interface LogEntry {
  id: string;
  timestamp: string;
  type: LogType;
  message: string;
  player?: string;
}

const logMessages: Record<LogType, string[]> = {
  LOGIN: [
    "{player} logged in from 192.168.1.{ip}",
    "{player} connected to game server",
    "{player} authenticated successfully",
  ],
  LOGOUT: [
    "{player} logged out (played {min}m)",
    "{player} disconnected (timeout)",
    "{player} left the game",
  ],
  COMBAT: [
    "{player} defeated Demon Skeleton [Level 120]",
    "{player} killed Dragon Lord — loot: Golden Armor",
    "{player} was killed by Hydra at Forgotten Temple",
    "{player} dealt 4,832 damage to Warlock",
    "PvP: {player} defeated ShadowMage in arena",
  ],
  TRADE: [
    "{player} sold Magic Plate Armor for 45,000 gp",
    "{player} bought 100x Mana Potions for 5,000 gp",
    "{player} traded Crossbow +3 with NightElf",
    "Market: Golden Boots listed by {player} for 120,000 gp",
  ],
  VIP: [
    "{player} activated VIP Ouro (30 days)",
    "{player} VIP Prata expired — renewal pending",
    "{player} purchased VIP Bronze upgrade",
    "VIP bonus applied: +15% EXP for {player}",
  ],
  RESET: [
    "{player} performed reset #12 at level 1000",
    "{player} reset character — new base level 1",
    "{player} completed reset milestone: 10 resets",
  ],
  SYSTEM: [
    "Server save completed in 2.3s",
    "Backup created: db_backup_20260315.sql",
    "Maintenance window scheduled: 04:00-04:30 UTC",
    "Cache cleared: 1,247 expired entries removed",
    "Monster respawn cycle completed for zone 3",
  ],
};

const players = [
  "DragonSlayer99", "NightElf", "BladeMaster", "ArcaneWiz",
  "ThunderAxe", "FrostHunter", "ShadowMage", "IronFist",
  "LunarWitch", "PixelKnight",
];

function generateLogs(count: number): LogEntry[] {
  const types: LogType[] = ["LOGIN", "LOGOUT", "COMBAT", "TRADE", "VIP", "RESET", "SYSTEM"];
  const entries: LogEntry[] = [];
  const base = new Date("2026-03-15T12:00:00Z");

  for (let i = 0; i < count; i++) {
    const type = types[Math.floor(Math.random() * types.length)];
    const msgs = logMessages[type];
    const msg = msgs[Math.floor(Math.random() * msgs.length)];
    const player = players[Math.floor(Math.random() * players.length)];
    const ts = new Date(base.getTime() + i * 120_000);

    entries.push({
      id: `log-${i}`,
      timestamp: ts.toISOString(),
      type,
      player: type !== "SYSTEM" ? player : undefined,
      message: msg
        .replace("{player}", player)
        .replace("{ip}", String(Math.floor(Math.random() * 254) + 1))
        .replace("{min}", String(Math.floor(Math.random() * 180) + 10)),
    });
  }
  return entries;
}

export const mockLogs = generateLogs(50);

export const logTypeColors: Record<LogType, string> = {
  LOGIN: "#378ADD",
  LOGOUT: "#378ADD",
  COMBAT: "#D85A30",
  TRADE: "#1D9E75",
  VIP: "#EF9F27",
  RESET: "#7F77DD",
  SYSTEM: "#888780",
};
