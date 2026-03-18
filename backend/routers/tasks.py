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
    where_clause = {}
    if status:
        where_clause["status"] = status
    if agent_slug:
        where_clause["ownerId"] = agent_slug
        
    tasks = await prisma.task.find_many(
        where=where_clause,
        take=limit,
        order={"createdAt": "desc"},
        include={"owner": True}
    )
    return tasks

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
            "pineconeQueryIds": [],
            "owner": {
                "connect": {"slug": body.owner_slug}
            }
        }
    )
    return {"task_id": task.id}
