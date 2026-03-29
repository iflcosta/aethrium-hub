export interface SystemCard {
  name: string;
  description: string;
  status: "implemented" | "pending";
  revenue: string;
  agent: string;
  progress: number;
  tag: string;
}

export const systems: SystemCard[] = [
  {
    name: "Dodge / Critical / Reflect",
    description: "Gacha system for combat enhancement stones with weighted random drops",
    status: "implemented",
    revenue: "R$300–3.000/mês",
    agent: "Thiago",
    progress: 100,
    tag: "dodge-stones",
  },
  {
    name: "VIP System",
    description: "3-tier VIP (Bronze R$15, Prata R$25, Ouro R$40) with exclusive perks",
    status: "implemented",
    revenue: "R$190–1.875/mês",
    agent: "Rafael",
    progress: 100,
    tag: "vip",
  },
  {
    name: "Stamina Refill",
    description: "4 refill plans (3h R$10, 42h R$25, Infinite 7d R$50) for hunting stamina",
    status: "implemented",
    revenue: "R$250–1.800/mês",
    agent: "Rafael",
    progress: 100,
    tag: "stamina",
  },
  {
    name: "Reset System",
    description: "Character reset at level 1000, preserving skill points and unlocking cosmetics",
    status: "pending",
    revenue: "Indirect — retention",
    agent: "Thiago",
    progress: 25,
    tag: "reset",
  },
  {
    name: "Guild Points",
    description: "Guild ranking system with weekly rewards based on accumulated points",
    status: "pending",
    revenue: "Indirect — engagement",
    agent: "Viktor",
    progress: 10,
    tag: "guild-points",
  },
  {
    name: "Mining / Refinement",
    description: "Resource gathering and weapon upgrade crafting system",
    status: "pending",
    revenue: "R$100–800/mês",
    agent: "Beatriz",
    progress: 5,
    tag: "mining",
  },
];
