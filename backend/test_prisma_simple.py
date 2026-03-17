import asyncio
import os
from dotenv import load_dotenv
from prisma import Prisma

# Force load backend/.env
env_path = os.path.join(os.path.dirname(__file__), ".env")
load_dotenv(env_path)

async def test_prisma():
    print("Testing Prisma connection...")
    db = Prisma()
    try:
        await db.connect()
        print("Connected successfully!")
        
        # Try to find Carlos
        agent = await db.agent.find_unique(where={"slug": "carlos"})
        if agent:
            print(f"Found agent: {agent.display_name}")
        else:
            print("Carlos not found.")
            
        await db.disconnect()
        print("Disconnected.")
    except Exception as e:
        print(f"ERROR: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    asyncio.run(test_prisma())
