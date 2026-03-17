import os
from pathlib import Path
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv
from contextlib import asynccontextmanager
from backend.db import prisma
from backend.scheduler import start_scheduler, stop_scheduler

# Explicitly load the backend/.env file
env_path = Path(__file__).parent / ".env"
load_dotenv(dotenv_path=env_path)

if not os.getenv("PINECONE_API_KEY"):
    print("[WARNING] PINECONE_API_KEY not found in environment!")
else:
    print("[INFO] PINECONE_API_KEY loaded successfully.")

# Unified lifespan and app initialization
@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup logic
    await prisma.connect()
    start_scheduler()
    print("[INFO] Scheduler started")
    yield
    # Shutdown logic
    stop_scheduler()
    print("[INFO] Scheduler stopped")
    await prisma.disconnect()

app = FastAPI(title="Aethrium Studio LangGraph API", lifespan=lifespan)

# Update CORS to allow requests from the frontend
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:3000",
        "http://127.0.0.1:3000",
        "http://localhost:3001",
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers here later
from backend.routers import agents, stream, tasks, projects, webhooks
app.include_router(agents.router)
app.include_router(stream.router)
app.include_router(tasks.router)
app.include_router(projects.router)
app.include_router(webhooks.router)

@app.get("/health")
async def health_check():
    return {"status": "ok"}
