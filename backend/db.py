import os
os.environ["PRISMA_BINARY_PLATFORM"] = "debian-openssl-3.0.x"

from prisma import Prisma
prisma = Prisma()

async def connect_db():
    await prisma.connect()

async def disconnect_db():
    await prisma.disconnect()
