import os
import asyncio
from utils import log_event

os.environ["PRISMA_BINARY_PLATFORM"] = "debian-openssl-3.0.x"
os.environ["PYTHON_PRISMA_BINARY_PLATFORM"] = "debian-openssl-3.0.x"

from prisma import Prisma
prisma = Prisma()

async def connect_db():
    db_url = os.getenv("DATABASE_URL", "")
    # Mask URL for logging: postgresql://user:***@host:port/db
    masked_url = "NOT SET"
    if db_url:
        try:
            from urllib.parse import urlparse
            parsed = urlparse(db_url)
            masked_url = f"{parsed.scheme}://{parsed.username}:***@{parsed.hostname}:{parsed.port}{parsed.path}"
        except:
            masked_url = "INVALID FORMAT"
            
    log_event(f"[DB] Attempting to connect to Prisma... (URL: {masked_url})")
    try:
        # 20s timeout to prevent hanging during Render deployment
        await asyncio.wait_for(prisma.connect(), timeout=20.0)
        log_event("[DB] Prisma connected successfully")
    except asyncio.TimeoutError:
        log_event("[ERROR] Prisma connection timed out after 20 seconds")
    except Exception as e:
        log_event(f"[ERROR] Prisma connection failed: {e}")

async def disconnect_db():
    if prisma.is_connected():
        await prisma.disconnect()
        log_event("[DB] Prisma disconnected")
