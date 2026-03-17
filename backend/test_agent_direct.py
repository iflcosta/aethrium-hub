import asyncio
import os
import json
from dotenv import load_dotenv

# Force load backend/.env
env_path = os.path.join(os.path.dirname(__file__), ".env")
load_dotenv(env_path)

from agents.sophia import SophiaAgent

async def test_sophia():
    print(f"Testing Sophia Agent...")
    print(f"ENV Path: {env_path}")
    print(f"API KEY present: {bool(os.getenv('GOOGLE_API_KEY'))}")
    
    agent = SophiaAgent()
    
    # Create a dummy task to satisfy FK constraint
    task = await prisma.task.create(
        data={
            "title": "Manual Diagnostic",
            "ownerId": (await prisma.agent.find_unique(where={"slug": "carlos"})).id,
            "status": "PENDING"
        }
    )
    task_id = task.id
    context = {
        "prompt": "Olá, pode se apresentar?",
        "execution_id": None
    }
    
    full_response = ""
    try:
        async for chunk_str in agent.run(task_id, context):
            # chunk_str is "data: {...}\n\n"
            if chunk_str.startswith("data: "):
                try:
                    data = json.loads(chunk_str[6:].strip())
                    chunk = data.get("chunk", "")
                    print(chunk, end="", flush=True)
                    full_response += chunk
                except:
                    pass
        print("\n" + "="*20)
        print(f"Full response length: {len(full_response)} characters")
        if len(full_response) == 0:
            print("ERROR: Response is empty!")
    except Exception as e:
        print(f"\nFATAL ERROR during run: {e}")
    finally:
        # Check model used in execution
        if task_id:
            exec_rec = await prisma.execution.find_first(where={"taskId": task_id}, order={"startedAt": "desc"})
            if exec_rec:
                print(f"Model used for final execution: {exec_rec.model}")
                print(f"Execution status: {exec_rec.status}")

if __name__ == "__main__":
    from backend.db import prisma
    async def run_all():
        await prisma.connect()
        await test_sophia()
        await prisma.disconnect()
    
    asyncio.run(run_all())
