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

    specialist_execution_ids = {}

    # Rodar especialistas em paralelo (exceto Carlos)
    for slug in body.agent_slugs:
        if slug == "carlos" or slug not in agents:
            continue

        agent = agents[slug]
        agent_db = await prisma.agent.find_unique(where={"slug": slug})

        subtask = await prisma.task.create(
            data={
                "title": f"Contribuição de {agent.display_name}",
                "ownerId": agent_db.id if agent_db else carlos_agent.id,
                "parentTaskId": meeting_task.id,
                "status": "RUNNING"
            }
        )
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
        specialist_execution_ids[slug] = execution.id

        async def run_specialist(ag, t_id, ex_id):
            try:
                async for _ in ag.run(t_id, {
                    "prompt": body.topic,
                    "execution_id": ex_id,
                    "meeting_topic": body.topic,
                    **body.context
                }):
                    pass
            except Exception as e:
                print(f"[MEETING] {ag.slug} falhou: {e}")

        asyncio.create_task(run_specialist(agent, subtask.id, execution.id))

    # Criar execução do Carlos (síntese) — começa após especialistas terminarem
    carlos_execution = await prisma.execution.create(
        data={
            "taskId": meeting_task.id,
            "agentSlug": "carlos",
            "model": agents["carlos"].model,
            "promptTokens": 0,
            "compTokens": 0,
            "thoughtChunks": Json([])
        }
    )

    asyncio.create_task(_synthesis_coordinator(
        topic=body.topic,
        specialist_execution_ids=list(specialist_execution_ids.values()),
        carlos_execution_id=carlos_execution.id,
        meeting_task_id=meeting_task.id,
        context=body.context
    ))

    return {
        "task_id": meeting_task.id,
        "execution_ids": specialist_execution_ids,
        "carlos_execution_id": carlos_execution.id
    }


async def _synthesis_coordinator(
    topic: str,
    specialist_execution_ids: list,
    carlos_execution_id: str,
    meeting_task_id: str,
    context: dict
):
    """Espera todos os especialistas terminarem e roda Carlos para sintetizar."""
    import json as _json

    # Espera até 5 minutos
    for _ in range(100):
        await asyncio.sleep(3)
        if not specialist_execution_ids:
            break
        executions = await prisma.execution.find_many(
            where={"id": {"in": specialist_execution_ids}}
        )
        if all(e.status in ["COMPLETED", "FAILED"] for e in executions):
            break

    # Coleta respostas
    executions = await prisma.execution.find_many(
        where={"id": {"in": specialist_execution_ids}}
    )
    responses = []
    for e in executions:
        if e.status == "COMPLETED" and e.result:
            res = e.result if isinstance(e.result, dict) else _json.loads(e.result)
            text = res.get("text", "").strip()
            if text:
                responses.append(f"**{e.agentSlug.capitalize()}**: {text[:1500]}")

    if not responses:
        responses = ["Nenhum especialista respondeu a tempo."]

    synthesis_prompt = (
        f"Tópico da reunião: {topic}\n\n"
        f"Respostas dos especialistas:\n\n"
        + "\n\n---\n\n".join(responses)
        + "\n\n---\n\n"
        "Com base nas perspectivas acima, sintetize uma decisão técnica consolidada. "
        "Identifique consensos, conflitos e próximos passos claros. "
        "Seja direto e prático."
    )

    try:
        async for _ in agents["carlos"].run(meeting_task_id, {
            "prompt": synthesis_prompt,
            "execution_id": carlos_execution_id,
            "meeting_topic": topic,
            **context
        }):
            pass
        print(f"[MEETING] Síntese do Carlos concluída.")
    except Exception as e:
        print(f"[MEETING] Carlos falhou na síntese: {e}")


@router.post("/meeting/message")
async def meeting_message(body: MeetingMessageRequest):
    return {"status": "Message queued to meeting"}

@router.get("/{slug}/executions")
async def get_agent_executions(slug: str, limit: int = 5):
    """Returns the most recent completed executions for an agent (for history loading)."""
    executions = await prisma.execution.find_many(
        where={"agentSlug": slug, "status": "COMPLETED"},
        order={"createdAt": "desc"},
        take=limit,
        include={"task": True},
    )
    results = []
    for e in executions:
        result = e.result if isinstance(e.result, dict) else {}
        text = result.get("text", "").strip() if result else ""
        if not text and e.thoughtChunks:
            chunks = e.thoughtChunks if isinstance(e.thoughtChunks, list) else []
            text = "".join(chunks).strip()
        if not text:
            continue
        results.append({
            "id": e.id,
            "task_title": e.task.title if e.task else "",
            "text": text,
            "created_at": e.createdAt.isoformat() if e.createdAt else None,
            "scheduled": "scheduled" in (e.task.description or "") if e.task else False,
        })
    return results


@router.get("/")
async def get_agents():
    db_agents = await prisma.agent.find_many()
    agent_map = {a.slug: a for a in db_agents}

    all_tasks = await prisma.task.find_many(where={"status": "COMPLETED"})
    owner_task_count: dict = {}
    for t in all_tasks:
        owner_task_count[t.ownerId] = owner_task_count.get(t.ownerId, 0) + 1

    all_execs = await prisma.execution.find_many(where={"status": "COMPLETED"})
    slug_token_sum: dict = {}
    for e in all_execs:
        slug_token_sum[e.agentSlug] = slug_token_sum.get(e.agentSlug, 0) + e.compTokens

    result = []
    for k, v in agents.items():
        db_a = agent_map.get(k)
        tasks_done = owner_task_count.get(db_a.id, 0) if db_a else 0
        result.append({
            "slug": k,
            "displayName": v.display_name,
            "model": v.model,
            "role": v.role,
            "color": db_a.color if db_a else "gray",
            "isOnline": db_a.isOnline if db_a else False,
            "tasksCompleted": tasks_done,
            "tokensUsed": slug_token_sum.get(k, 0),
        })
    return result
