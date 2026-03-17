const { PrismaClient } = require('@prisma/client');

async function main() {
  const prisma = new PrismaClient({
    datasources: {
      db: {
        url: 'postgresql://postgres:ZpvY6GtvvQWUM5KT@db.wpoqimsahieymjcrxgdj.supabase.co:6543/postgres?sslmode=require'
      }
    }
  });

  const agents = [
    { slug: "carlos", displayName: "Carlos", model: "gpt-4o", role: "CTO", color: "purple", isOnline: true },
    { slug: "rafael", displayName: "Rafael", model: "gpt-4o", role: "BACKEND", color: "teal", isOnline: true },
    { slug: "viktor", displayName: "Viktor", model: "gpt-4o", role: "FRONTEND", color: "teal", isOnline: true },
    { slug: "sophia", displayName: "Sophia", model: "gpt-4o", role: "QA", color: "blue", isOnline: true },
    { slug: "mariana", displayName: "Mariana", model: "gpt-4o", role: "SUPPORT", color: "amber", isOnline: false },
    { slug: "lucas", displayName: "Lucas", model: "gpt-4o", role: "CM", color: "amber", isOnline: false },
    { slug: "beatriz", displayName: "Beatriz", model: "gpt-4o", role: "MAPPER", color: "coral", isOnline: true },
    { slug: "thiago", displayName: "Thiago", model: "gpt-4o", role: "BALANCER", color: "gray", isOnline: false },
    { slug: "amanda", displayName: "Amanda", model: "gpt-4o", role: "DEVOPS", color: "gray", isOnline: true },
    { slug: "leonardo", displayName: "Leonardo", model: "gpt-4o", role: "RESEARCH", color: "gray", isOnline: true },
  ];

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
  await prisma.$disconnect();
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
