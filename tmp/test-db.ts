import { PrismaClient } from "@prisma/client";
import "dotenv/config";

const prisma = new PrismaClient();

async function main() {
  console.log("Testing DB connection...");
  console.log("DB URL:", process.env.DATABASE_URL?.substring(0, 20) + "...");
  try {
    const agentsCount = await prisma.agent.count();
    console.log("Agents count:", agentsCount);
  } catch (err) {
    console.error("DB connection failed:", err);
  } finally {
    await prisma.$disconnect();
  }
}

main();
