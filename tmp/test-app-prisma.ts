import "dotenv/config";
import { Pool } from "pg";
import { PrismaPg } from "@prisma/adapter-pg";
import { PrismaClient } from "@prisma/client";

const prismaClientSingleton = () => {
  const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: {
      rejectUnauthorized: false,
    },
  });
  const adapter = new PrismaPg(pool);
  return new PrismaClient({ adapter });
};

const prisma = prismaClientSingleton();

async function main() {
  console.log("Testing App Prisma logic...");
  try {
    const agents = await prisma.agent.findMany();
    console.log("Agents found:", agents.length);
    console.log("Agents data:", JSON.stringify(agents, null, 2));
  } catch (err) {
    console.error("App Prisma test failed:", err);
  } finally {
    await prisma.$disconnect();
  }
}

main();
