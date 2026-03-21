import asyncio
import json
import re
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

            # Prepare messages with history memory (Part 8)
            from langchain_core.messages import AIMessage
            messages = [SystemMessage(content=enhanced_system)]
            
            history = context.get("history", [])
            for h in history:
                if h.get("role") == "user":
                    messages.append(HumanMessage(content=h.get("content", "")))
                else:
                    messages.append(AIMessage(content=h.get("content", "")))

            ctx_str = json.dumps(context, indent=2)
            full_content = f"Context:\n{ctx_str}\n\nTask:\n{prompt}"
            messages.append(HumanMessage(content=full_content))
            
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
                        print(f"[AGENT] Chunk received: {str(content)[:50]}")
                        data = {"seq": len(chunks), "chunk": str(content), "ts": ""}
                        yield f"data: {json.dumps(data)}\n\n"

                        # Write chunks to DB every 5 so stream.py polling sees real-time updates
                        if len(chunks) % 5 == 0:
                            await prisma.execution.update(
                                where={"id": execution.id},
                                data={"thoughtChunks": Json(chunks)}
                            )
            except Exception as e:
                print(f"[ERROR] Gemini run failed for {self.slug} using {active_model}:")
                traceback.print_exc()
                raise e

            full_response = "".join(chunks)
            print(f"[DEBUG] Gemini response received: {len(full_response)} chars, {len(chunks)} chunks")

            # Flush any remaining chunks not yet written (total may not be a multiple of 5)
            if chunks:
                await prisma.execution.update(
                    where={"id": execution.id},
                    data={"thoughtChunks": Json(chunks)}
                )

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

            # Auto-handoff: Rafael → Sophia when Lua code is present
            handoff_info = None
            if (
                self.slug == "rafael"
                and "```lua" in full_response
                and not context.get("handoff_from")
            ):
                handoff_info = await self._setup_sophia_handoff(task_id, full_response, context)
                if handoff_info:
                    print(f"[HANDOFF] Rafael → Sophia | execution={handoff_info['execution_id']}")
                    asyncio.create_task(
                        self._run_sophia_handoff(handoff_info, task_id, full_response, context)
                    )

            # 1. thoughtChunks is already the list of plain-text token strings
            #    captured during streaming. Use it directly.
            all_chunks = chunks

            # 2. Save result
            result_obj = {"text": full_response}
            if self.slug == "carlos" or "meeting_topic" in context:
                result_obj["final_delivery"] = full_response
                await notify_task_completed(context.get("title", "Task"), self.display_name, full_response)
            if handoff_info:
                result_obj["handoff"] = handoff_info

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
        await update_task_status(task_id, "HANDOFF_PENDING")
        await log_agent_event(self.slug, task_id, "handoff_initiated", {"target": target_slug, "reason": reason})

    async def _setup_sophia_handoff(self, parent_task_id: str, rafael_output: str, context: dict) -> dict | None:
        """Creates Sophia's Task + Execution in the DB and returns handoff info."""
        from prisma import Json
        sophia_db = await prisma.agent.find_unique(where={"slug": "sophia"})
        if not sophia_db:
            print("[HANDOFF] Sophia not found in DB, skipping")
            return None

        sophia_task = await prisma.task.create(data={
            "title": f"QA — {context.get('title', 'código de Rafael')}",
            "description": "Handoff automático: Rafael → Sophia",
            "ownerId": sophia_db.id,
            "parentTaskId": parent_task_id,
            "status": "RUNNING",
            "priority": 2,
        })

        sophia_execution = await prisma.execution.create(data={
            "taskId": sophia_task.id,
            "agentSlug": "sophia",
            "model": "gemini-3-flash-preview",
            "promptTokens": 0,
            "compTokens": 0,
            "thoughtChunks": Json([]),
        })

        return {
            "to": "sophia",
            "execution_id": sophia_execution.id,
            "task_id": sophia_task.id,
        }

    async def _run_sophia_handoff(self, handoff_info: dict, parent_task_id: str, rafael_output: str, context: dict):
        """Runs Sophia as a background task to QA Rafael's Lua code."""
        from graphs.studio_graph import agents as all_agents
        sophia = all_agents.get("sophia")
        if not sophia:
            return

        lua_blocks = re.findall(r"```lua\n(.*?)\n```", rafael_output, re.DOTALL)
        lua_combined = "\n\n".join(lua_blocks) if lua_blocks else rafael_output[:1000]

        sophia_prompt = (
            "Rafael implementou o seguinte código Lua. Faça o QA completo.\n\n"
            f"```lua\n{lua_combined}\n```\n\n"
            f"Contexto do Rafael:\n{rafael_output[:600]}\n\n"
            "Escreva testes em blocos ```lua ``` para execução automática no sandbox E2B. "
            "Produza os blocos: [PLANO DE TESTES], [CASOS DE BORDA], [RESULTADO], [BUGS ENCONTRADOS]."
        )

        try:
            async for _ in sophia.run(handoff_info["task_id"], {
                "prompt": sophia_prompt,
                "execution_id": handoff_info["execution_id"],
                "handoff_from": "rafael",
                "parent_task_id": parent_task_id,
            }):
                pass
            print(f"[HANDOFF] Sophia QA done for execution={handoff_info['execution_id']}")
        except Exception as e:
            print(f"[HANDOFF] Sophia QA failed: {e}")
