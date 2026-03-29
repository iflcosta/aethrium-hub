from db import prisma
from prisma import Json

async def get_task(task_id: str):
    """Fetch task with owner and executions"""
    return await prisma.task.find_unique(
        where={"id": task_id},
        include={"owner": True, "executions": True}
    )

async def update_task_status(task_id: str, status: str):
    """Update task status"""
    return await prisma.task.update(
        where={"id": task_id},
        data={"status": status}
    )

async def create_subtask(parent_id: str, title: str, description: str, owner_slug: str):
    """Create a subtask"""
    return await prisma.task.create(
        data={
            "title": title,
            "description": description,
            "ownerId": owner_slug,
            "status": "PENDING",
            "priority": 2, # default normal
            # Optional: link parent if schema supports it, assuming it's unlinked for now or needs parentId
        }
    )

async def log_agent_event(agent_identifier: str, task_id: str, event: str, payload: dict):
    """Log an agent event using slug or ID."""
    import json
    
    # Try to find agent by slug if not a CUID/UUID
    agent_id = agent_identifier
    if len(agent_identifier) < 20:
        agent = await prisma.agent.find_unique(where={"slug": agent_identifier})
        if agent:
            agent_id = agent.id

    try:
        return await prisma.agentLog.create(
            data={
                "agentId": agent_id,
                "taskId": task_id,
                "event": event,
                "payload": Json(payload)
            }
        )
    except Exception as e:
        print(f"[LOG_ERROR] Failed to log event '{event}': {e}")
        return None

async def initiate_handoff(task_id: str, target_slug: str, reason: str):
    """Initiate a handoff"""
    await update_task_status(task_id, "HANDOFF_PENDING")
    # In a real implementation we would update handoffTargetId on the task
    # For now we'll just log it
    await log_agent_event("system", task_id, "handoff_initiated", {"target": target_slug, "reason": reason})
    return {"status": "success"}
