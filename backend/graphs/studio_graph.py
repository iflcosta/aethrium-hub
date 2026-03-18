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
}

class StudioState(TypedDict):
    task_id: str
    current_agent: str
    messages: list
    context_snapshot: dict
    status: str
    handoff_target: Optional[str]
    urgent: bool
    final_delivery: str
    gatekeeper_validated: bool

def create_agent_node(agent_slug: str):
    def node(state: StudioState):
        state["current_agent"] = agent_slug
        
        # In a real implementation we get the agent's actual generated string here
        # For urgent checks:
        output_text = " ".join([m for m in state.get("messages", []) if isinstance(m, str)])
        urgent_keywords = ["URGENTE", "SERVIDOR CAIU", "EXPLOIT", "VULNERABILIDADE CRÍTICA"]
        
        if agent_slug in ["amanda", "mariana", "sophia"]:
            if any(k in output_text.upper() for k in urgent_keywords):
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
builder.add_edge(START, "carlos_node")

def route_after_agent(state: StudioState) -> str:
    if state.get("handoff_target"):
        return "handoff_node"
        
    current = state.get("current_agent")
    
    # Urgent bypass for specific agents
    if state.get("urgent") and current in ["amanda", "mariana", "sophia"]:
        return END
        
    # Everyone routes to Carlos to act as gatekeeper
    if current != "carlos":
        return "carlos_node"
        
    # If it is Carlos, and no handoff, we are done
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
