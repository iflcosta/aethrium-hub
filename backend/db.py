import os
import asyncio
from utils import log_event

os.environ["PRISMA_BINARY_PLATFORM"] = "debian-openssl-3.0.x"
os.environ["PYTHON_PRISMA_BINARY_PLATFORM"] = "debian-openssl-3.0.x"

from prisma import Prisma
prisma = Prisma()

async def connect_db():
    log_event("[DB] Attempting to connect to Prisma...")
    try:
        # 20s timeout to prevent hanging during Render deployment
        await asyncio.wait_for(prisma.connect(), timeout=20.0)
        log_event("[DB] Prisma connected successfully")
    except asyncio.TimeoutError:
        log_event("[ERROR] Prisma connection timed out after 20 seconds")
        # We allow it to continue so health checks can still respond if necessary,
        # or it will fail later when a query is made.
    except Exception as e:
        log_event(f"[ERROR] Prisma connection failed: {e}")

async def disconnect_db():
    if prisma.is_connected():
        await prisma.disconnect()
        log_event("[DB] Prisma disconnected")
