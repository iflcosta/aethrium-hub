import asyncio
from datetime import datetime
from fastapi import APIRouter
from pydantic import BaseModel
from typing import Dict, Any, List

from utils import log_event
from graphs.studio_graph import agents
from db import prisma
from prisma import Json

router = APIRouter(prefix="/agents", tags=["Agents"])

class RunRequest(BaseModel):
    task_id: str
    prompt: str
    context: Dict[str, Any]

class MeetingRequest(BaseModel):
    topic: str
    agent_slugs: list[str]
    context: Dict[str, Any]

class MeetingMessageRequest(BaseModel):
    task_id: str
    message: str

class ModelUpdateRequest(BaseModel):
    model: str

@router.put("/{slug}/model")
async def update_agent_model(slug: str, body: ModelUpdateRequest):
    if slug not in agents:
        return {"error": "Agent not found"}, 404
    
    # Update in-memory registry
    agents[slug].model = body.model
    
    # Update Database
    await prisma.agent.update(
        where={"slug": slug},
        data={"model": body.model}
    )
        
    return {"slug": slug, "model": body.model, "updated": True}

@router.post("/{slug}/run")
async def run_agent(slug: str, body: RunRequest):
    log_event(f"Request: POST /agents/{slug}/run - task_id: {body.task_id}")
    if slug not in agents:
        return {"error": "Agent not found"}, 404
        
    agent = agents[slug]
    
    # In a full implementation, we might invoke the LangGraph here,
    # but based on the BaseAgent definition, run() returns an AsyncGenerator
    # that streams database thought chunks directly to SSE. 
    # Since FastAPI doesn't easily return an SSE stream AND start background tasks
    # on the same simple endpoint (except via BackgroundTasks wrapper or custom SSE loop),
    # To match the requirements: "starts LangGraph graph in background, returns execution_id"
    # we need the run() method to be triggered.
    
    log_event(f"T1: Finding task {body.task_id}")
    task = await prisma.task.find_unique(where={"id": body.task_id})
    if not task:
        log_event(f"T1.1: Task not found, creating one")
        # We need a valid ownerId. Let's find the agent in the DB.
        agent_db = await prisma.agent.find_unique(where={"slug": slug})
        if not agent_db:
            agent_db = await prisma.agent.find_unique(where={"slug": "carlos"})
        
        if not agent_db:
            log_event(f"E1: Database not seeded: no agents found")
            return {"error": "Database not seeded: no agents found"}, 500
            
        task = await prisma.task.create(
            data={
                "id": body.task_id,
                "title": f"Chat with {slug}",
                "ownerId": agent_db.id,
                "status": "RUNNING"
            }
        )

    log_event(f"T2: Creating execution record for {slug}")
    execution = await prisma.execution.create(
        data={
            "taskId": task.id,
            "agentSlug": slug,
            "model": agent.model,
            "promptTokens": 0,
            "compTokens": 0,
            "thoughtChunks": Json([]) 
        }
    )
    log_event(f"T3: Execution created: {execution.id}")
    
    async def process_run(ex_id: str):
        try:
            log_event(f"BG: Starting agent {slug} run process")
            # We inject execution_id into context so BaseAgent.run can use/update it 
            # instead of creating a new one. (Requires small update in base_agent later)
            async for chunk in agent.run(body.task_id, {**body.context, "prompt": body.prompt, "execution_id": ex_id}):
                pass 
        except Exception as e:
            log_event(f"BG: Agent run failed: {e}")
            import traceback
            traceback.print_exc()

    asyncio.create_task(process_run(execution.id))
    
    return {"execution_id": execution.id}

@router.post("/meeting/start")
async def start_meeting(body: MeetingRequest):
    # Removed redundant internal prisma = Prisma() calls
    
    # 1. Create a Task with title = topic, owner = carlos
    carlos_agent = await prisma.agent.find_unique(where={"slug": "carlos"})
    if not carlos_agent:
        return {"error": "Carlos agent not found in DB"}, 500
        
    meeting_task = await prisma.task.create(
        data={
            "title": body.topic,
            "description": "Meeting task",
            "ownerId": carlos_agent.id,
            "status": "RUNNING"
        }
    )
    
    execution_ids = {}
    
    # 2. For each agent in agent_slugs (except carlos)
    for slug in body.agent_slugs:
        if slug == "carlos" or slug not in agents:
            continue
            
        agent = agents[slug]
        agent_db = await prisma.agent.find_unique(where={"slug": slug})
        
        # Create subtask
        subtask = await prisma.task.create(
            data={
                "title": f"Contribuição de {agent.display_name} para a reunião",
                "ownerId": agent_db.id if agent_db else carlos_agent.id,
                "parentTaskId": meeting_task.id,
                "status": "RUNNING"
            }
        )

        # Create Execution
        execution = await prisma.execution.create(
            data={
                "taskId": subtask.id,
                "agentSlug": slug,
                "model": agent.model,
                "promptTokens": 0,
                "compTokens": 0,
                "thoughtChunks": Json([])
            }
        )
        execution_ids[slug] = execution.id
        
        async def process_meeting_run(ag, t_id, ex_id, prmpt):
            try:
                # Same approach, run and consume directly
                async for chunk in ag.run(t_id, {"prompt": prmpt, "execution_id": ex_id, "meeting_topic": body.topic}):
                    pass
            except Exception as e:
                print(f"Meeting run failed for {ag.slug}: {e}")

        asyncio.create_task(process_meeting_run(agent, subtask.id, execution.id, body.topic))
        
    # In a full flow, Carlos would wait for all to finish, then summarize.
    # For now, we return the tasks so the UI can stream them.
    return {
        "task_id": meeting_task.id,
        "execution_ids": execution_ids
    }

@router.post("/meeting/message")
async def meeting_message(body: MeetingMessageRequest):
    # Sends follow-up message to all agents in the meeting.
    # Placeholder for the expanded meeting logic.
    return {"status": "Message queued to meeting"}

@router.get("/")
async def get_agents():
    # Returns all agents from mock or DB. For now return static definitions
    return [
        {"slug": k, "displayName": v.display_name, "model": v.model, "role": v.role}
        for k, v in agents.items()
    ]
