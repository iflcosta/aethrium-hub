export type MockTaskStatus = "PENDING" | "RUNNING" | "COMPLETED" | "FAILED" | "CANCELLED";

export interface MockTask {
  id: string;
  title: string;
  description: string;
  status: MockTaskStatus;
  priority: number;
  ownerSlug: string;
  ownerName: string;
  ownerColor: string;
  handoffTargetSlug?: string;
  systemTag?: string;
  contextSnapshot?: Record<string, unknown>;
  createdAt: string;
  updatedAt: string;
}

export const mockTasks: MockTask[] = [
  { id: "t1", title: "Implement Dodge Stone gacha", description: "Create the Lua script for dodge stone random drop with weighted probabilities", status: "COMPLETED", priority: 3, ownerSlug: "thiago", ownerName: "Thiago", ownerColor: "gray", systemTag: "dodge-stones", contextSnapshot: { dropRates: { common: 0.6, rare: 0.3, epic: 0.1 } }, createdAt: "2026-03-10T10:00:00Z", updatedAt: "2026-03-12T14:30:00Z" },
  { id: "t2", title: "VIP Bronze tier activation flow", description: "Wire up VIP Bronze purchase → activation → buff application", status: "COMPLETED", priority: 2, ownerSlug: "rafael", ownerName: "Rafael", ownerColor: "teal", systemTag: "vip", createdAt: "2026-03-09T08:00:00Z", updatedAt: "2026-03-11T16:00:00Z" },
  { id: "t3", title: "Stamina refill 3h plan", description: "Implement the 3-hour stamina refill consumable", status: "COMPLETED", priority: 2, ownerSlug: "rafael", ownerName: "Rafael", ownerColor: "teal", systemTag: "stamina", createdAt: "2026-03-08T09:00:00Z", updatedAt: "2026-03-10T12:00:00Z" },
  { id: "t4", title: "Critical Stone balance pass", description: "Adjust critical stone percentages based on QA feedback", status: "RUNNING", priority: 3, ownerSlug: "thiago", ownerName: "Thiago", ownerColor: "gray", systemTag: "dodge-stones", createdAt: "2026-03-13T10:00:00Z", updatedAt: "2026-03-15T10:00:00Z" },
  { id: "t5", title: "VIP Ouro exclusive mount", description: "Create exclusive mount sprite and movement speed bonus for Ouro tier", status: "RUNNING", priority: 1, ownerSlug: "viktor", ownerName: "Viktor", ownerColor: "teal", systemTag: "vip", createdAt: "2026-03-13T14:00:00Z", updatedAt: "2026-03-15T11:00:00Z" },
  { id: "t6", title: "Stamina UI bar rendering", description: "Render stamina bar in HUD with animated depletion", status: "RUNNING", priority: 2, ownerSlug: "viktor", ownerName: "Viktor", ownerColor: "teal", systemTag: "stamina", createdAt: "2026-03-14T08:00:00Z", updatedAt: "2026-03-15T09:00:00Z" },
  { id: "t7", title: "Reset system level requirement", description: "Implement level 1000 requirement check for character reset", status: "PENDING", priority: 3, ownerSlug: "rafael", ownerName: "Rafael", ownerColor: "teal", systemTag: "reset", createdAt: "2026-03-15T08:00:00Z", updatedAt: "2026-03-15T08:00:00Z" },
  { id: "t8", title: "Guild Points ranking board", description: "Create ranking board view sorted by guild points", status: "PENDING", priority: 1, ownerSlug: "viktor", ownerName: "Viktor", ownerColor: "teal", systemTag: "guild-points", createdAt: "2026-03-15T09:00:00Z", updatedAt: "2026-03-15T09:00:00Z" },
  { id: "t9", title: "Mining node placement", description: "Place mining nodes in Forgotten Temple zones 1-3", status: "PENDING", priority: 2, ownerSlug: "beatriz", ownerName: "Beatriz", ownerColor: "coral", systemTag: "mining", createdAt: "2026-03-15T10:00:00Z", updatedAt: "2026-03-15T10:00:00Z" },
  { id: "t10", title: "Reflect Stone QA suite", description: "Write automated tests for reflect stone damage calculation", status: "RUNNING", priority: 2, ownerSlug: "sophia", ownerName: "Sophia", ownerColor: "blue", systemTag: "dodge-stones", createdAt: "2026-03-14T13:00:00Z", updatedAt: "2026-03-15T08:30:00Z" },
  { id: "t11", title: "VIP Prata perks document", description: "Document all Prata tier perks for community announcement", status: "PENDING", priority: 1, ownerSlug: "lucas", ownerName: "Lucas", ownerColor: "amber", systemTag: "vip", createdAt: "2026-03-15T07:00:00Z", updatedAt: "2026-03-15T07:00:00Z" },
  { id: "t12", title: "Stamina Infinite 7d pricing analysis", description: "Analyze pricing for 7-day infinite stamina against competitor servers", status: "COMPLETED", priority: 2, ownerSlug: "leonardo", ownerName: "Leonardo", ownerColor: "gray", systemTag: "stamina", createdAt: "2026-03-07T11:00:00Z", updatedAt: "2026-03-09T15:00:00Z" },
  { id: "t13", title: "Server deployment pipeline", description: "Set up CI/CD for automated server builds", status: "RUNNING", priority: 3, ownerSlug: "amanda", ownerName: "Amanda", ownerColor: "gray", createdAt: "2026-03-12T08:00:00Z", updatedAt: "2026-03-15T12:00:00Z" },
  { id: "t14", title: "Forgotten Temple zone 2 map", description: "Complete zone 2 tilemap with monster spawns and loot chests", status: "RUNNING", priority: 2, ownerSlug: "beatriz", ownerName: "Beatriz", ownerColor: "coral", createdAt: "2026-03-11T10:00:00Z", updatedAt: "2026-03-15T11:30:00Z" },
  { id: "t15", title: "Player ticket response templates", description: "Create response templates for common player issues", status: "PENDING", priority: 1, ownerSlug: "mariana", ownerName: "Mariana", ownerColor: "amber", createdAt: "2026-03-15T06:00:00Z", updatedAt: "2026-03-15T06:00:00Z" },
];
