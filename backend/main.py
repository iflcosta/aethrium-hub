import os
from pathlib import Path
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv
from contextlib import asynccontextmanager
from datetime import datetime
from db import prisma
from scheduler import start_scheduler, stop_scheduler

# Explicitly load the backend/.env file and override system variables
env_path = Path(__file__).parent / ".env"
load_dotenv(dotenv_path=env_path, override=True)

if not os.getenv("PINECONE_API_KEY"):
    print("[WARNING] PINECONE_API_KEY not found in environment!")
else:
    print("[INFO] PINECONE_API_KEY loaded successfully.")

# Unified lifespan and app initialization
@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup logic
    print(f"[INFO] Starting backend... env: {os.getenv('RENDER_SERVICE_ID', 'local')}")
    try:
        print("[INFO] Connecting to Prisma...")
        await prisma.connect()
        print("[INFO] Prisma connected successfully")
    except Exception as e:
        print(f"[ERROR] Prisma connection failed: {e}")
        # We don't raise here so the app can at least start and serve health checks
        # Though the app will be degraded.
    
    try:
        start_scheduler()
        print("[INFO] Scheduler started")
    except Exception as e:
        print(f"[ERROR] Scheduler failed to start: {e}")
        
    yield
    # Shutdown logic
    stop_scheduler()
    print("[INFO] Scheduler stopped")
    try:
        await prisma.disconnect()
        print("[INFO] Prisma disconnected")
    except:
        pass

app = FastAPI(title="Aethrium Studio LangGraph API", lifespan=lifespan)

# Simple in-memory logger for debugging without Render Dashboard
DEBUG_LOGS = []

def log_event(message: str):
    timestamp = datetime.now().isoformat()
    DEBUG_LOGS.append(f"[{timestamp}] {message}")
    if len(DEBUG_LOGS) > 100:
        DEBUG_LOGS.pop(0)
    print(message)

@app.get("/debug-logs")
async def get_debug_logs():
    return {"logs": DEBUG_LOGS}

@app.post("/test-cors")
async def test_cors():
    log_event("Received /test-cors POST request")
    return {"status": "CORS should be working if you can see this"}

# Update CORS to allow requests from any origin (Failsafe)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers here later
from routers import agents, stream, tasks, projects, webhooks
app.include_router(agents.router)
app.include_router(stream.router)
app.include_router(tasks.router)
app.include_router(projects.router)
app.include_router(webhooks.router)

@app.get("/")
async def root():
    return {
        "status": "ok", 
        "message": "Aethrium Studio API is running",
        "version": "1.0.0",
        "documentation": "/docs"
    }

@app.get("/health")
async def health_check():
    db_status = "connected" if prisma.is_connected() else "disconnected"
    return {
        "status": "ok",
        "database": db_status,
        "environment": os.getenv("RENDER_SERVICE_ID", "local")
    }
