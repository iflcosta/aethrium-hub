import asyncio
from db import prisma

agents_data = [
    {"slug": "carlos", "displayName": "Carlos", "model": "gemini-3.1-pro-preview", "role": "CTO", "color": "purple", "isOnline": True},
    {"slug": "rafael", "displayName": "Rafael", "model": "gemini-3.1-pro-preview", "role": "BACKEND", "color": "teal", "isOnline": True},
    {"slug": "viktor", "displayName": "Viktor", "model": "gemini-3.1-pro-preview", "role": "FRONTEND", "color": "teal", "isOnline": True},
    {"slug": "sophia", "displayName": "Sophia", "model": "gemini-2.5-flash", "role": "QA", "color": "blue", "isOnline": True},
    {"slug": "mariana", "displayName": "Mariana", "model": "gemini-2.5-flash", "role": "SUPPORT", "color": "amber", "isOnline": False},
    {"slug": "lucas", "displayName": "Lucas", "model": "gemini-2.5-flash", "role": "CM", "color": "amber", "isOnline": False},
    {"slug": "beatriz", "displayName": "Beatriz", "model": "gemini-2.5-flash", "role": "MAPPER", "color": "coral", "isOnline": True},
    {"slug": "thiago", "displayName": "Thiago", "model": "gemini-2.5-flash", "role": "BALANCER", "color": "gray", "isOnline": False},
    {"slug": "amanda", "displayName": "Amanda", "model": "gemini-2.5-flash", "role": "DEVOPS", "color": "gray", "isOnline": True},
    {"slug": "leonardo", "displayName": "Leonardo", "model": "gemini-2.5-flash", "role": "RESEARCH", "color": "gray", "isOnline": True},
]

async def seed():
    print("Starting python seed...")
    await prisma.connect()
    for agent in agents_data:
        try:
            await prisma.agent.upsert(
                where={"slug": agent["slug"]},
                data={"create": agent, "update": agent}
            )
            print(f"Upserted: {agent['slug']}")
        except Exception as e:
            print(f"Failed to upsert {agent['slug']}: {e}")
    await prisma.disconnect()
    print("Seed finished.")

if __name__ == "__main__":
    asyncio.run(seed())
