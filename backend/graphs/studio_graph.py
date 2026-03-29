from typing import TypedDict, List, Optional
from langgraph.graph import StateGraph, START, END

# Import all agents
from agents.carlos import CarlosAgent
from agents.rafael import RafaelAgent
from agents.viktor import ViktorAgent
from agents.sophia import SophiaAgent
from agents.mariana import MarianaAgent
from agents.lucas import LucasAgent
from agents.beatriz import BeatrizAgent
from agents.thiago import ThiagoAgent
from agents.amanda import AmandaAgent
from agents.leonardo import LeonardoAgent
from agents.diego import DiegoAgent
from agents.ana import AnaAgent

# Instantiate agents
agents = {
    "carlos": CarlosAgent(),
    "rafael": RafaelAgent(),
    "viktor": ViktorAgent(),
    "sophia": SophiaAgent(),
    "mariana": MarianaAgent(),
    "lucas": LucasAgent(),
    "beatriz": BeatrizAgent(),
    "thiago": ThiagoAgent(),
    "amanda": AmandaAgent(),
    "leonardo": LeonardoAgent(),
    "diego": DiegoAgent(),
    "ana": AnaAgent(),
}

class StudioState(TypedDict):
    task_id: str
    current_agent: str
    messages: list
    context_snapshot: dict
    status: str
    handoff_target: Optional[str]
    pipeline: List[str]  # Lista de agentes para execução sequencial
    urgent: bool
    final_delivery: str
    gatekeeper_validated: bool

def create_agent_node(agent_slug: str):
    async def node(state: StudioState):
        state["current_agent"] = agent_slug
        agent = agents.get(agent_slug)
        if not agent:
            return state

        task_id = state.get("task_id")
        # Snapshot do contexto focado em não perder o histórico
        context = state.get("context_snapshot", {})
        context["history"] = state.get("messages", [])
        
        full_response = ""
        handoff_suggested = None
        pipeline_suggested = []
        
        try:
            async for _ in agent.run(task_id, context):
                pass
            
            from db import prisma
            execution = await prisma.execution.find_first(
                where={"taskId": task_id, "agentSlug": agent_slug},
                order={"createdAt": "desc"}
            )
            
            if execution and execution.result:
                import json
                res_data = execution.result
                if isinstance(res_data, str):
                    res_data = json.loads(res_data)
                
                full_response = res_data.get("text", "")
                handoff_suggested = res_data.get("handoff")
                # Se o agente sugerir um pipeline (como o Carlos faria)
                pipeline_suggested = res_data.get("pipeline", [])
                
        except Exception as e:
            print(f"[GRAPH] Error running agent {agent_slug}: {e}")
            state["status"] = "FAILED"
            return state

        state["messages"].append({"role": "assistant", "content": full_response, "agent": agent_slug})
        
        if handoff_suggested:
            state["handoff_target"] = handoff_suggested.get("to")
        
        if pipeline_suggested:
            state["pipeline"] = pipeline_suggested
            
        # Urgent checks
        urgent_keywords = ["URGENTE", "SERVIDOR CAIU", "EXPLOIT", "VULNERABILIDADE CRÍTICA"]
        if agent_slug in ["amanda", "mariana", "sophia"]:
            if any(k in full_response.upper() for k in urgent_keywords):
                state["urgent"] = True
                
        return state
    return node

def handoff_node(state: StudioState):
    if state.get("handoff_target"):
        state["current_agent"] = state["handoff_target"]
        state["handoff_target"] = None
    return state

# Setup graph
builder = StateGraph(StudioState)

# Add nodes
for slug in agents.keys():
    builder.add_node(f"{slug}_node", create_agent_node(slug))

builder.add_node("handoff_node", handoff_node)

# Edges
# Dynamic Entry
def route_start(state: StudioState) -> str:
    target = state.get("current_agent", "carlos")
    return f"{target}_node"

builder.add_conditional_edges(START, route_start)

def route_after_agent(state: StudioState) -> str:
    # 1. Prioridade para Handoff Explícito
    if state.get("handoff_target"):
        return "handoff_node"
    
    # 2. Resposta Urgente bypass
    if state.get("urgent"):
        return END

    # 3. Se houver um Pipeline ativo, pega o próximo
    pipeline = state.get("pipeline", [])
    if pipeline:
        next_agent = pipeline.pop(0)
        state["pipeline"] = pipeline # atualiza a lista
        state["handoff_target"] = next_agent
        return "handoff_node"
        
    current = state.get("current_agent")
    
    # 4. Todos voltam para Carlos para validação final se não houver mais nada
    if current != "carlos":
        return "carlos_node"
        
    return END

# Connect all agents to conditional routing
for slug in agents.keys():
    builder.add_conditional_edges(f"{slug}_node", route_after_agent)

def route_after_handoff(state: StudioState) -> str:
    target = state.get("current_agent")
    if target and f"{target}_node" in builder.nodes:
        return f"{target}_node"
    return END

builder.add_conditional_edges("handoff_node", route_after_handoff)

graph = builder.compile()
