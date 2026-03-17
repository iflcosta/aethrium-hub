export interface MockAgent {
  id: string;
  slug: string;
  displayName: string;
  model: string;
  role: string;
  color: string;
  isOnline: boolean;
  tasksCompleted: number;
  tokensUsed: number;
  lastActivity: string;
}

export const mockAgents: MockAgent[] = [
  { id: "clk_carlos", slug: "carlos", displayName: "Carlos", model: "gemini-3.1-pro-preview", role: "CTO", color: "purple", isOnline: true, tasksCompleted: 47, tokensUsed: 1_240_000, lastActivity: "Reviewing system architecture for mining module..." },
  { id: "clk_rafael", slug: "rafael", displayName: "Rafael", model: "gemini-3.1-pro-preview", role: "Lua Dev", color: "teal", isOnline: true, tasksCompleted: 38, tokensUsed: 980_000, lastActivity: "Implementing VIP tier expiration logic in Lua..." },
  { id: "clk_viktor", slug: "viktor", displayName: "Viktor", model: "gemini-3.1-pro-preview", role: "C++ Dev", color: "teal", isOnline: true, tasksCompleted: 31, tokensUsed: 870_000, lastActivity: "Building stamina bar HUD component..." },
  { id: "clk_sophia", slug: "sophia", displayName: "Sophia", model: "gemini-2.5-flash", role: "QA Engineer", color: "blue", isOnline: true, tasksCompleted: 52, tokensUsed: 1_100_000, lastActivity: "Running regression tests on dodge stone system..." },
  { id: "clk_amanda", slug: "amanda", displayName: "Amanda", model: "gemini-2.5-flash", role: "DevOps", color: "gray", isOnline: true, tasksCompleted: 19, tokensUsed: 420_000, lastActivity: "Monitoring server deploy pipeline..." },
  { id: "clk_beatriz", slug: "beatriz", displayName: "Beatriz", model: "gemini-2.5-flash", role: "Mapper", color: "coral", isOnline: true, tasksCompleted: 28, tokensUsed: 650_000, lastActivity: "Mapping Forgotten Temple dungeon zone 3..." },
  { id: "clk_leonardo", slug: "leonardo", displayName: "Leonardo", model: "gemini-2.5-flash", role: "Research", color: "gray", isOnline: true, tasksCompleted: 15, tokensUsed: 380_000, lastActivity: "Analyzing competitor monetization strategies..." },
  { id: "clk_thiago", slug: "thiago", displayName: "Thiago", model: "gemini-2.5-flash", role: "Balancer", color: "gray", isOnline: false, tasksCompleted: 22, tokensUsed: 540_000, lastActivity: "Calibrating stamina refill price curves..." },
  { id: "clk_lucas", slug: "lucas", displayName: "Lucas", model: "gemini-2.5-flash", role: "CM", color: "amber", isOnline: false, tasksCompleted: 33, tokensUsed: 290_000, lastActivity: "Drafting community patch notes for v1.4..." },
  { id: "clk_mariana", slug: "mariana", displayName: "Mariana", model: "gemini-2.5-flash", role: "Support", color: "amber", isOnline: false, tasksCompleted: 41, tokensUsed: 310_000, lastActivity: "Responding to player ticket about VIP renewal..." },
];
