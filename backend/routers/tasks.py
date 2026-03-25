from fastapi import APIRouter, Query
from pydantic import BaseModel
from typing import Optional, Dict, Any
from db import prisma
from prisma import Json
import json

router = APIRouter(prefix="/tasks", tags=["Tasks"])

class CreateTaskRequest(BaseModel):
    title: str
    description: str
    owner_slug: str
    priority: str = "MEDIUM"
    context: Optional[Dict[str, Any]] = None

@router.get("/")
async def get_tasks(
    status: Optional[str] = None,
    agent_slug: Optional[str] = None,
    limit: int = Query(50, le=100)
):
    # isChat=True tasks are ephemeral chats — never show in Kanban
    where_clause: Dict[str, Any] = {"isChat": False}
    if status:
        where_clause["status"] = status
    if agent_slug:
        where_clause["owner"] = {"is": {"slug": agent_slug}}

    tasks = await prisma.task.find_many(
        where=where_clause,
        take=limit,
        order={"createdAt": "desc"},
        include={"owner": True}
    )
    return tasks


@router.post("/cleanup")
async def cleanup_tasks():
    """
    Mark stuck RUNNING tasks as FAILED and delete all ephemeral chat tasks.
    Safe to call at any time. Also triggered automatically on server startup.
    """
    from datetime import datetime, timedelta

    # 1. Delete chat tasks (ephemeral) — cascade via delete_many on executions first
    chat_tasks = await prisma.task.find_many(
        where={"isChat": True}
    )
    chat_deleted = 0
    for t in chat_tasks:
        await prisma.execution.delete_many(where={"taskId": t.id})
        await prisma.agentlog.delete_many(where={"taskId": t.id})
        await prisma.task.delete(where={"id": t.id})
        chat_deleted += 1

    # 2. Also clean up legacy "Chat with X" tasks (before isChat field existed)
    legacy_tasks = await prisma.task.find_many(
        where={"title": {"startswith": "Chat with"}}
    )
    for t in legacy_tasks:
        await prisma.execution.delete_many(where={"taskId": t.id})
        await prisma.agentlog.delete_many(where={"taskId": t.id})
        try:
            await prisma.task.delete(where={"id": t.id})
        except Exception:
            pass
        chat_deleted += 1

    # 3. Mark RUNNING tasks older than 30 min as FAILED
    cutoff = datetime.utcnow() - timedelta(minutes=30)
    stuck = await prisma.task.find_many(
        where={"status": "RUNNING", "updatedAt": {"lt": cutoff}}
    )
    for t in stuck:
        await prisma.task.update(
            where={"id": t.id},
            data={"status": "FAILED"}
        )
    await prisma.execution.update_many(
        where={"status": "RUNNING", "startedAt": {"lt": cutoff}},
        data={"status": "FAILED", "error": "Timeout — tarefa interrompida pelo cleanup"}
    )

    return {
        "chat_tasks_deleted": chat_deleted,
        "stuck_tasks_failed": len(stuck),
    }

@router.delete("/{task_id}")
async def delete_task(task_id: str):
    await prisma.execution.delete_many(where={"taskId": task_id})
    await prisma.agentlog.delete_many(where={"taskId": task_id})
    await prisma.task.delete(where={"id": task_id})
    return {"deleted": task_id}

@router.post("/")
async def create_task(body: CreateTaskRequest):
    # Map string priority to Int for database
    priority_map = {
        "LOW": 1,
        "MEDIUM": 2,
        "HIGH": 3,
        "CRITICAL": 4
    }
    db_priority = priority_map.get(body.priority.upper(), 2)

    task = await prisma.task.create(
        data={
            "title": body.title,
            "description": body.description or "",
            "priority": db_priority,
            "status": "PENDING",
            "contextSnapshot": Json({
                "summary": body.description or body.title,
                "project": body.context.get("project_slug", "") if body.context else "",
                "created_via": "command_center"
            }),
            "owner": {
                "connect": {"slug": body.owner_slug}
            }
        }
    )
    return {"task_id": task.id}
