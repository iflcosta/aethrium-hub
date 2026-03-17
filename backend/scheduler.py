import asyncio
from datetime import datetime
import os

running = False

async def schedule_loop():
    global running
    print("[SCHEDULER] Scheduler started")
    while running:
        # Check for scheduled tasks here
        # For now, just a heartbeat
        # print(f"[SCHEDULER] Heartbeat: {datetime.now()}")
        await asyncio.sleep(60)
    print("[SCHEDULER] Scheduler stopped")

def start_scheduler():
    global running
    if not running:
        running = True
        asyncio.create_task(schedule_loop())

def stop_scheduler():
    global running
    running = False

if __name__ == "__main__":
    # Test
    running = True
    asyncio.run(schedule_loop())
