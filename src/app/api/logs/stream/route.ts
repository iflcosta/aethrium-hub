import { mockLogs, logTypeColors, type LogType } from "@/lib/mock/logs";

const players = ["DragonSlayer99", "NightElf", "BladeMaster", "ArcaneWiz", "ThunderAxe", "FrostHunter", "ShadowMage", "IronFist"];
const types: LogType[] = ["LOGIN", "LOGOUT", "COMBAT", "TRADE", "VIP", "RESET", "SYSTEM"];

const templates: Record<LogType, string[]> = {
  LOGIN: ["{p} logged in", "{p} connected"],
  LOGOUT: ["{p} logged out", "{p} disconnected"],
  COMBAT: ["{p} defeated Demon Skeleton", "{p} killed Dragon Lord"],
  TRADE: ["{p} sold Magic Plate Armor", "{p} bought 100x Mana Potions"],
  VIP: ["{p} activated VIP Ouro", "{p} VIP renewed"],
  RESET: ["{p} performed reset at level 1000"],
  SYSTEM: ["Server save completed", "Cache cleared", "Monster respawn cycle done"],
};

export async function GET() {
  const encoder = new TextEncoder();
  const stream = new ReadableStream({
    start(controller) {
      let i = 0;
      const interval = setInterval(() => {
        const type = types[Math.floor(Math.random() * types.length)];
        const msgs = templates[type];
        const msg = msgs[Math.floor(Math.random() * msgs.length)];
        const player = players[Math.floor(Math.random() * players.length)];

        const entry = {
          id: `live-${Date.now()}-${i}`,
          timestamp: new Date().toISOString(),
          type,
          player: type !== "SYSTEM" ? player : undefined,
          message: msg.replace("{p}", player),
          color: logTypeColors[type],
        };

        controller.enqueue(encoder.encode(`data: ${JSON.stringify(entry)}\n\n`));
        i++;
        if (i > 500) {
          clearInterval(interval);
          controller.close();
        }
      }, 2000);
    },
  });

  return new Response(stream, {
    headers: {
      "Content-Type": "text/event-stream",
      "Cache-Control": "no-cache",
      Connection: "keep-alive",
    },
  });
}
