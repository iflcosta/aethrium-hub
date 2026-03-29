import asyncio
from db import prisma

agents_data = [
    {"slug": "carlos",   "displayName": "[CTO] Carlos",   "model": "llama-3.3-70b-versatile", "role": "CTO",        "color": "purple", "isOnline": True},
    {"slug": "rafael",   "displayName": "[LUA] Rafael",   "model": "llama-3.3-70b-versatile", "role": "LUA_DEV",    "color": "teal",   "isOnline": True},
    {"slug": "viktor",   "displayName": "[C++] Viktor",   "model": "llama-3.3-70b-versatile", "role": "CPP_DEV",    "color": "blue",   "isOnline": True},
    {"slug": "sophia",   "displayName": "[QA] Sophia",    "model": "llama-3.1-8b-instant",    "role": "QA",         "color": "coral",  "isOnline": True},
    {"slug": "beatriz",  "displayName": "[MAP] Beatriz",  "model": "llama-3.1-8b-instant",    "role": "MAPPER",     "color": "amber",  "isOnline": True},
    {"slug": "thiago",   "displayName": "[BAL] Thiago",   "model": "llama-3.1-8b-instant",    "role": "BALANCER",   "color": "gray",   "isOnline": False},
    {"slug": "amanda",   "displayName": "[OPS] Amanda",   "model": "llama-3.1-8b-instant",    "role": "DEVOPS",     "color": "gray",   "isOnline": True},
    {"slug": "leonardo", "displayName": "[RES] Leonardo", "model": "llama-3.1-8b-instant",    "role": "RESEARCH",   "color": "gray",   "isOnline": False},
    {"slug": "lucas",    "displayName": "[CM] Lucas",     "model": "llama-3.1-8b-instant",    "role": "CM",         "color": "amber",  "isOnline": False},
    {"slug": "mariana",  "displayName": "[SUP] Mariana",  "model": "llama-3.1-8b-instant",    "role": "SUPPORT",    "color": "amber",  "isOnline": False},
    {"slug": "diego",    "displayName": "[ART] Diego",    "model": "llama-3.1-8b-instant",    "role": "DESIGNER",   "color": "purple", "isOnline": False},
    {"slug": "ana",      "displayName": "[LORE] Ana",     "model": "llama-3.1-8b-instant",    "role": "LORE_WRITER","color": "purple", "isOnline": False},
]

async def seed():
    print("Starting seed...")
    await prisma.connect()
    for agent in agents_data:
        try:
            await prisma.agent.upsert(
                where={"slug": agent["slug"]},
                data={"create": agent, "update": agent}
            )
            print(f"  Upserted: {agent['slug']}")
        except Exception as e:
            print(f"  Failed:   {agent['slug']}: {e}")
    await prisma.disconnect()
    print("Seed finished.")

if __name__ == "__main__":
    asyncio.run(seed())
