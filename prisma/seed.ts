import "dotenv/config";
import { PrismaClient, AgentRole } from "@prisma/client";

const prisma = new PrismaClient();

const agents = [
  {
    slug: "carlos",
    displayName: "Carlos",
    model: "gemini-3.1-pro-preview",
    role: AgentRole.CTO,
    color: "#7F77DD",
    isOnline: true,
  },
  {
    slug: "rafael",
    displayName: "Rafael",
    model: "gemini-3.1-pro-preview",
    role: AgentRole.BACKEND,
    color: "#2DD4BF",
    isOnline: true,
  },
  {
    slug: "viktor",
    displayName: "Viktor",
    model: "gemini-3.1-pro-preview",
    role: AgentRole.FRONTEND,
    color: "#2DD4BF",
    isOnline: true,
  },
  {
    slug: "sophia",
    displayName: "Sophia",
    model: "gemini-2.5-flash",
    role: AgentRole.QA,
    color: "#3B82F6",
    isOnline: true,
  },
  {
    slug: "mariana",
    displayName: "Mariana",
    model: "gemini-2.5-flash",
    role: AgentRole.SUPPORT,
    color: "#F59E0B",
    isOnline: false,
  },
  {
    slug: "lucas",
    displayName: "Lucas",
    model: "gemini-2.5-flash",
    role: AgentRole.CM,
    color: "#F59E0B",
    isOnline: false,
  },
  {
    slug: "beatriz",
    displayName: "Beatriz",
    model: "gemini-2.5-flash",
    role: AgentRole.MAPPER,
    color: "#FB7185",
    isOnline: true,
  },
  {
    slug: "thiago",
    displayName: "Thiago",
    model: "gemini-2.5-flash",
    role: AgentRole.BALANCER,
    color: "#6B7280",
    isOnline: false,
  },
  {
    slug: "amanda",
    displayName: "Amanda",
    model: "gemini-2.5-flash",
    role: AgentRole.DEVOPS,
    color: "#6B7280",
    isOnline: true,
  },
  {
    slug: "leonardo",
    displayName: "Leonardo",
    model: "gemini-2.5-flash",
    role: AgentRole.RESEARCH,
    color: "#6B7280",
    isOnline: true,
  },
];

async function main() {
  console.log("Start seeding...");
  for (const agent of agents) {
    const upsertedAgent = await prisma.agent.upsert({
      where: { slug: agent.slug },
      update: agent,
      create: agent,
    });
    console.log(`Upserted agent: ${upsertedAgent.displayName}`);
  }
  console.log("Seeding finished.");
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
