import os
import json
from pathlib import Path
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import Response
from dotenv import load_dotenv
from contextlib import asynccontextmanager
from db import prisma, connect_db, disconnect_db
from scheduler import start_scheduler, stop_scheduler, get_scheduler_status, trigger_job
from utils import log_event, DEBUG_LOGS

# Explicitly load the backend/.env file (if it exists) but DO NOT override OS environment variables
# (This ensures Render dashboard variables take priority over any file accidentally in the image)
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
    log_event("[STARTUP] Initializing ecosystem...")
    log_event("[STARTUP] Connecting to database...")
    await connect_db()
    
    try:
        log_event("[STARTUP] Starting scheduler...")
        start_scheduler()
        log_event("[STARTUP] Scheduler started")
    except Exception as e:
        log_event(f"[ERROR] Scheduler failed to start: {e}")

    # Auto-cleanup: remove stale tasks from previous server sessions
    try:
        from datetime import datetime, timedelta

        # Delete legacy "Chat with X" tasks (created before isChat field)
        legacy_chat = await prisma.task.find_many(
            where={"title": {"startswith": "Chat with"}}
        )
        for t in legacy_chat:
            await prisma.execution.delete_many(where={"taskId": t.id})
            await prisma.agentlog.delete_many(where={"taskId": t.id})
            try:
                await prisma.task.delete(where={"id": t.id})
            except Exception:
                pass

        # Delete ephemeral chat tasks (isChat=True) — safe after migration
        try:
            chat_tasks = await prisma.task.find_many(
                where={"isChat": True}
            )
            for t in chat_tasks:
                await prisma.execution.delete_many(where={"taskId": t.id})
                await prisma.agentlog.delete_many(where={"taskId": t.id})
                try:
                    await prisma.task.delete(where={"id": t.id})
                except Exception:
                    pass
        except Exception:
            pass  # isChat column may not exist yet — skip silently

        # Mark RUNNING tasks/executions older than 30 min as FAILED
        cutoff = datetime.utcnow() - timedelta(minutes=30)
        await prisma.task.update_many(
            where={"status": "RUNNING", "updatedAt": {"lt": cutoff}},
            data={"status": "FAILED"}
        )
        await prisma.execution.update_many(
            where={"status": "RUNNING", "startedAt": {"lt": cutoff}},
            data={"status": "FAILED", "error": "Interrompido por reinício do servidor"}
        )
        log_event(f"[STARTUP] Cleanup done: {len(legacy_chat)} legacy chat tasks removed")
    except Exception as e:
        log_event(f"[STARTUP] Cleanup warning (non-fatal): {e}")

    log_event("[STARTUP] Application startup complete")
    yield
    # Shutdown logic
    log_event("[SHUTDOWN] Stopping processes...")
    stop_scheduler()
    log_event("[SHUTDOWN] Scheduler stopped")
    await disconnect_db()
    log_event("[SHUTDOWN] Cleanup complete")

app = FastAPI(title="Aethrium Studio LangGraph API", lifespan=lifespan)

@app.get("/debug-logs")
async def get_debug_logs():
    # Return last 100 logs to avoid huge payload
    return {"logs": DEBUG_LOGS[-100:]}

@app.post("/test-cors")
async def test_cors():
    log_event("Received /test-cors POST request")
    return {"status": "CORS should be working if you can see this"}

# Raw ASGI middleware: injects CORS headers on EVERY response (including 500 crashes)
@app.middleware("http")
async def add_cors_headers(request: Request, call_next):
    origin = request.headers.get("origin", "*")
    if request.method == "OPTIONS":
        return Response(
            status_code=200,
            headers={
                "Access-Control-Allow-Origin": origin,
                "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
                "Access-Control-Allow-Headers": "*",
                "Access-Control-Max-Age": "86400",
                "Access-Control-Allow-Credentials": "false",
            }
        )
    
    try:
        response = await call_next(request)
    except Exception as e:
        log_event(f"Unhandled server error: {str(e)}")
        # On crash, return a 500 with CORS headers
        return Response(
            content=json.dumps({"error": "Internal Server Error", "detail": str(e)}),
            status_code=500,
            headers={
                "Access-Control-Allow-Origin": origin,
                "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
                "Access-Control-Allow-Headers": "*",
                "Content-Type": "application/json"
            }
        )
        
    response.headers["Access-Control-Allow-Origin"] = origin
    response.headers["Access-Control-Allow-Methods"] = "GET, POST, PUT, DELETE, OPTIONS"
    response.headers["Access-Control-Allow-Headers"] = "*"
    return response

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

@app.get("/scheduler/status")
async def scheduler_status():
    return get_scheduler_status()

@app.post("/scheduler/trigger/{key}")
async def scheduler_trigger(key: str):
    return await trigger_job(key)

@app.get("/health")
async def health_check():
    db_status = "connected" if prisma.is_connected() else "disconnected"
    pinecone_host = os.getenv("PINECONE_HOST", "")
    pinecone_index = os.getenv("PINECONE_INDEX", "aethrium-studio")
    return {
        "status": "ok",
        "database": db_status,
        "environment": os.getenv("RENDER_SERVICE_ID", "local"),
        "pinecone_index": pinecone_index,
        "pinecone_host_set": bool(pinecone_host),
        "pinecone_host_prefix": pinecone_host[:30] + "..." if pinecone_host else None,
    }
