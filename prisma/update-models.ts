import { PrismaClient } from '@prisma/client'
import { Pool } from 'pg'
import { PrismaPg } from '@prisma/adapter-pg'
import * as dotenv from 'dotenv'

dotenv.config()

process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0'

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: {
    rejectUnauthorized: false,
  },
})
const adapter = new PrismaPg(pool)
const prisma = new PrismaClient({ adapter })

async function main() {
  const updates = [
    { slug: 'carlos',   model: 'gemini-3.1-pro-preview' },
    { slug: 'rafael',   model: 'gemini-3.1-pro-preview' },
    { slug: 'viktor',   model: 'gemini-3.1-pro-preview' },
    { slug: 'sophia',   model: 'gemini-2.5-flash' },
    { slug: 'beatriz',  model: 'gemini-2.5-flash' },
    { slug: 'thiago',   model: 'gemini-2.5-flash' },
    { slug: 'amanda',   model: 'gemini-2.5-flash' },
    { slug: 'mariana',  model: 'gemini-2.5-flash' },
    { slug: 'lucas',    model: 'gemini-2.5-flash' },
    { slug: 'leonardo', model: 'gemini-2.5-flash' },
  ]

  for (const u of updates) {
    await prisma.agent.update({
      where: { slug: u.slug },
      data:  { model: u.model }
    })
    console.log(`✓ ${u.slug} → ${u.model}`)
  }
  console.log('✅ Todos os modelos atualizados.')
}

main()
  .catch(console.error)
  .finally(async () => {
    await prisma.$disconnect()
    await pool.end()
  })
