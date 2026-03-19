import json
from typing import AsyncGenerator
from prisma import Prisma
from tools.prisma_tools import update_task_status, log_agent_event
from integrations.discord import notify_task_completed, notify_urgent
from integrations.sandbox import run_lua_test
from integrations.vision import analyze_map_image, analyze_map_from_base64
import os
from dotenv import load_dotenv

load_dotenv()

# Avoid global instance if we want to ensure thread/async safety in background tasks
# Instead, we should probably receive a connected instance or ensure it's connected
# But for simplicity, let's keep it but ensure we don't 're-initialize' wrongly.
from db import prisma

STUDIO_CONTEXT = """
You are part of Aethrium Studio — an AI-powered game development studio
specialized in building, operating and monetizing OTServ (Open Tibia Server)
projects from the ground up.

The studio develops multiple OTServ projects sequentially and simultaneously.
Each project has its own client version, TFS engine variant, database, 
feature set, and monetization strategy.

You are one of 10 specialized agents in the studio team:
- Carlos (CTO) — architecture, decisions, task routing
- Rafael (Lua Dev) — server-side Lua scripting
- Viktor (C++ Dev) — TFS engine modifications
- Sophia (QA) — testing and quality assurance
- Mariana (Support) — player support and documentation
- Lucas (CM) — community management and marketing
- Beatriz (Mapper) — world building and map design
- Thiago (Balancer) — gameplay balance and economy
- Amanda (DevOps) — infrastructure and deployment
- Leonardo (Research) — market research and benchmarking

The active project details (client version, database, implemented systems,
pending features, monetization model) will always be provided in the
task context. Never assume a specific project — always read the context.

Always respond in Portuguese (Brazil).
"""

class BaseAgent:
    slug: str
    display_name: str
    model: str
    role: str

    @property
    def system_prompt(self) -> str:
        raise NotImplementedError("Subclasses must define their system_prompt")

    async def run(self, task_id: str, context: dict) -> AsyncGenerator[str, None]:
        import traceback
        # Trace agent execution
        print(f"[DEBUG] Starting agent {self.slug} with model {self.model}")
        print(f"[DEBUG] GOOGLE_API_KEY loaded: {bool(os.getenv('GOOGLE_API_KEY'))}")
        
        # Implementation for LangChain / Google Generative AI streaming
        from langchain_google_genai import ChatGoogleGenerativeAI
        from langchain_core.messages import SystemMessage, HumanMessage
        
        # 1. Get or Create Execution record
        execution_id = context.get("execution_id")
        from prisma import Json
        if execution_id:
            execution = await prisma.execution.find_unique(where={"id": execution_id})
            await prisma.execution.update(where={"id": execution_id}, data={"status": "RUNNING"})
        else:
            execution = await prisma.execution.create(
                data={
                    "task": {"connect": {"id": task_id}},
                    "agentSlug": self.slug,
                    "model": self.model,
                    "promptTokens": 0,
                    "compTokens": 0,
                    "status": "RUNNING",
                    "thoughtChunks": Json([]) # Start empty
                }
            )
        
        try:
            # Prepare messages
            from rag.indexer import query_rag
            project_slug = context.get("project_slug")
            prompt = context.get("prompt", "")

            rag_context = ""
            if project_slug and prompt:
                try:
                    chunks = await query_rag(
                        query_text=prompt,
                        project_slug=project_slug,
                        agent_slug=self.slug,
                        top_k=5
                    )
                    if chunks:
                        rag_context = "\n\n--- CONTEXTO DO PROJETO ---\n"
                        for chunk in chunks:
                            rag_context += (
                                f"\n[{chunk['source']}]\n"
                                f"{chunk['text'][:300]}\n"
                            )
                except Exception as e:
                    print(f"[RAG] Query failed: {e}")

            # Vision Hook (Beatriz)
            vision_analysis = ""
            if self.slug == "beatriz":
                img_path = context.get("image_path")
                img_b64 = context.get("image_base64")
                if img_path:
                    v_res = await analyze_map_image(img_path)
                    if v_res["status"] == "success":
                        vision_analysis = f"\n\n--- ANÁLISE VISUAL DO MAPA ---\n{v_res['analysis']}\n"
                elif img_b64:
                    v_res = await analyze_map_from_base64(img_b64)
                    if v_res["status"] == "success":
                        vision_analysis = f"\n\n--- ANÁLISE VISUAL DO MAPA ---\n{v_res['analysis']}\n"

            enhanced_system = self.system_prompt + rag_context + vision_analysis

            ctx_str = json.dumps(context, indent=2)
            full_content = f"Context:\n{ctx_str}\n\nTask:\n{prompt}"
            
            messages = [
                SystemMessage(content=enhanced_system),
                HumanMessage(content=full_content)
            ]
            
            chunks = []
            
            # Try primary model
            active_model = self.model
            print(f"[MODEL_RUN] Attempting {self.slug} with model {active_model}")
            
            try:
                llm = ChatGoogleGenerativeAI(
                    model=active_model,
                    temperature=0.7,
                    streaming=True,
                    google_api_key=os.getenv("GOOGLE_API_KEY")
                )
                async for chunk in llm.astream(messages):
                    if chunk.content:
                        # Extract text if content is a list/dict
                        content = chunk.content
                        if isinstance(content, list):
                            content = "".join([c.get("text", "") for c in content if isinstance(c, dict) and "text" in c])
                        
                        chunks.append(str(content))
                        data = {"seq": len(chunks), "chunk": str(content), "ts": ""} 
                        yield f"data: {json.dumps(data)}\n\n"
            except Exception as e:
                print(f"[ERROR] Gemini run failed for {self.slug} using {active_model}:")
                traceback.print_exc()
                raise e

            full_response = "".join(chunks)
            print(f"[DEBUG] Gemini response received: {len(full_response)} chars")
            
            # E2B Sandbox Hook (Sophia)
            if self.slug == "sophia" and "```lua" in full_response:
                import re
                lua_blocks = re.findall(r"```lua\n(.*?)\n```", full_response, re.DOTALL)
                if lua_blocks:
                    print(f"[SANDBOX] Running {len(lua_blocks)} Lua tests for Sophia")
                    sandbox_results = []
                    for i, code in enumerate(lua_blocks):
                        res = await run_lua_test(code, f"Teste {i+1}")
                        sandbox_results.append(res)
                    
                    results_text = "\n\n--- RESULTADOS DO SANDBOX E2B ---\n"
                    for r in sandbox_results:
                        status_emoji = "✅" if r["status"] == "success" else "❌"
                        results_text += f"\n{status_emoji} {r['test_description']}:\n"
                        if r["stdout"]: results_text += f"STDOUT: {r['stdout']}\n"
                        if r["stderr"]: results_text += f"STDERR: {r['stderr']}\n"
                        if r.get("message"): results_text += f"ERRO: {r['message']}\n"
                    
                    full_response += results_text
                    # Update data for frontend
                    yield f"data: {json.dumps({'seq': len(chunks)+1, 'chunk': results_text, 'ts': ''})}\n\n"

            # Discord Hook (Urgent)
            if "URGENTE" in full_response.upper():
                await notify_urgent(full_response, self.display_name)
            from datetime import datetime
            now_iso = datetime.utcnow().isoformat()
            
            # 1. Append full text as a single thoughtChunk (as requested)
            thought_chunk = {"seq": 0, "delta": full_response, "ts": now_iso}
            all_chunks = chunks + [json.dumps(thought_chunk)]
            
            # 2. Save result as {"text": ...}
            result_obj = {"text": full_response}
            if self.slug == "carlos" or "meeting_topic" in context:
                 result_obj["final_delivery"] = full_response
                 # Discord Hook (Task Completed)
                 await notify_task_completed(context.get("title", "Task"), self.display_name, full_response)
                
            await prisma.execution.update(
                where={"id": execution.id},
                data={
                    "status": "COMPLETED",
                    "finishedAt": datetime.utcnow(),
                    "thoughtChunks": Json(all_chunks),
                    "result": Json(result_obj), 
                    "model": active_model
                }
            )
            
        except Exception as e:
            print(f"[ERROR] Agent {self.slug} run failed:")
            traceback.print_exc()
            # On error
            await prisma.execution.update(
                where={"id": execution.id},
                data={
                    "status": "FAILED",
                    "error": str(e)
                }
            )
            raise e

    async def handoff(self, task_id: str, target_slug: str, reason: str):
        # Update Task status and (if schema allowed it) handoffTargetId
        await update_task_status(task_id, "HANDOFF_PENDING")
        await log_agent_event(self.slug, task_id, "handoff_initiated", {"target": target_slug, "reason": reason})
