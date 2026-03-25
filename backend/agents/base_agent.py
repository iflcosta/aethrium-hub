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
        print(f"[DEBUG] GROQ_API_KEY loaded: {bool(os.getenv('GROQ_API_KEY'))}")
        
        # Implementation for LangChain / Groq streaming
        from langchain_groq import ChatGroq
        from langchain_core.messages import SystemMessage, HumanMessage
        
        # 1. Get or Create Execution record
        execution_id = context.get("execution_id")
        from prisma import Json
        execution = None
        if execution_id:
            execution = await prisma.execution.find_unique(where={"id": execution_id})
            if execution and execution.agentSlug == self.slug:
                await prisma.execution.update(where={"id": execution_id}, data={"status": "RUNNING"})
            else:
                execution = None # Force creation for different agent or if not found
        
        if not execution:
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
            project_slug = context.get("project_slug") or context.get("project")
            prompt = context.get("prompt") or context.get("summary", "")

            rag_context = ""
            if project_slug and prompt:
                try:
                    from rag.rag_utils import extract_search_queries
                    history = context.get("history", [])
                    search_queries = await extract_search_queries(prompt, history, self.slug)
                    
                    print(f"[RAG] Search queries: {search_queries}")
                    all_chunks = []
                    for q in search_queries:
                        chunks = await query_rag(
                            query_text=q,
                            project_slug=project_slug,
                            agent_slug=self.slug,
                            top_k=3
                        )
                        if chunks:
                            all_chunks.extend(chunks)
                    
                    if all_chunks:
                        # Remove duplicates by ID
                        seen_ids = set()
                        unique_chunks = []
                        for c in all_chunks:
                            cid = c.get("id")
                            if cid not in seen_ids:
                                seen_ids.add(cid)
                                unique_chunks.append(c)

                        rag_context = "\n\n--- CONTEXTO DO PROJETO ---\n"
                        for chunk in unique_chunks[:5]: # Cap at 5 total
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

            # File Reading Hook (Rafael + Viktor)
            file_context = ""
            if self.slug in ("rafael", "viktor"):
                file_paths = context.get("file_paths", [])
                if file_paths:
                    from tools.file_tools import read_file
                    file_context = "\n\n--- ARQUIVOS DO PROJETO ---\n"
                    for fp in file_paths:
                        content = read_file(fp)
                        file_context += f"\n[{fp}]\n{content[:1500]}\n"

            # Image Generation Hook (Beatriz + Lucas + Mariana)
            image_gen_result = ""
            if self.slug in ("beatriz", "lucas", "mariana"):
                img_prompt = context.get("image_prompt")
                if img_prompt:
                    from integrations.image_gen import (
                        generate_map_concept,
                        generate_social_banner,
                        generate_guide_image,
                    )
                    if self.slug == "beatriz":
                        img_res = await generate_map_concept(img_prompt)
                    elif self.slug == "lucas":
                        img_res = await generate_social_banner(img_prompt)
                    else:
                        img_res = await generate_guide_image(img_prompt)
                    if img_res["status"] == "success":
                        image_gen_result = (
                            f"\n\n--- IMAGEM GERADA (POLLINATIONS) ---\n"
                            f"URL: {img_res['url']}\n"
                            f"Prompt usado: {img_res['prompt']}\n"
                        )

            enhanced_system = self.system_prompt + rag_context + vision_analysis + file_context + image_gen_result

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
                llm = ChatGroq(
                    model=active_model,
                    temperature=0.7,
                    api_key=os.getenv("GROQ_API_KEY"),
                    streaming=True,
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

            # Engine Linter Hook (Viktor)
            if self.slug == "viktor" and "```cpp" in full_response:
                from tools.viktor_tools import lint_cpp_engine
                cpp_blocks = re.findall(r"```cpp\n(.*?)\n```", full_response, re.DOTALL)
                if cpp_blocks:
                    print(f"[ENGINE] Linting {len(cpp_blocks)} C++ blocks for Viktor")
                    lint_results = []
                    for code in cpp_blocks:
                        res = await lint_cpp_engine(code, context)
                        lint_results.append(res)
                    
                    l_text = "\n\n--- VALIDAÇÃO DE ENGINE (VIKTOR) ---\n"
                    for i, r in enumerate(lint_results):
                        s_emoji = "✅" if r.get("status") == "pass" else "❌"
                        l_text += f"\n{s_emoji} Bloco {i+1}:\n"
                        for err in r.get("errors", []): l_text += f"- ERRO: {err}\n"
                        for war in r.get("warnings", []): l_text += f"- AVISO: {war}\n"
                        for sug in r.get("suggestions", []): l_text += f"- SUGESTÃO: {sug}\n"
                    
                    full_response += l_text
                    yield f"data: {json.dumps({'seq': len(chunks)+1, 'chunk': l_text, 'ts': ''})}\n\n"

            # Discord Hook (Urgent) — only when agent explicitly flags [URGENTE] at the start
            if full_response.strip().upper().startswith("[URGENTE]"):
                await notify_urgent(full_response[:800], self.display_name)
            from datetime import datetime
            now_iso = datetime.utcnow().isoformat()

            # Auto-handoff suggestion (Will be handled by StudioGraph)
            handoff_info = None
            if (
                self.slug == "rafael"
                and "```lua" in full_response
                and not context.get("handoff_from")
            ):
                handoff_info = {"to": "sophia", "reason": "Verificação de código Lua"}

            # Reverse handoff: Sophia → Rafael (Lua bugs) or Viktor (C++ bugs)
            if self.slug == "sophia" and not context.get("handoff_from"):
                if "[HANDOFF: rafael]" in full_response or "[HANDOFF:rafael]" in full_response:
                    handoff_info = {"to": "rafael", "reason": "Bugs encontrados em Lua — correção necessária"}
                elif "[HANDOFF: viktor]" in full_response or "[HANDOFF:viktor]" in full_response:
                    handoff_info = {"to": "viktor", "reason": "Bugs encontrados em C++ — correção necessária"}

            # Discord notification for Lucas and Amanda on scheduled/deployment completions
            if self.slug == "lucas" and context.get("scheduled"):
                from integrations.discord import notify_task_completed
                await notify_task_completed(
                    context.get("title", "Conteúdo Semanal"),
                    self.display_name,
                    full_response
                )
            if self.slug == "amanda" and "[SISTEMA DEPLOYADO:" in full_response:
                import re as _re
                deploy_match = _re.search(r"\[SISTEMA DEPLOYADO:\s*(.*?)\]", full_response)
                if deploy_match:
                    from integrations.discord import notify_system_deployed
                    await notify_system_deployed(deploy_match.group(1).strip())

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

            # Extração de Pipeline (para Carlos ou qualquer agente que queira sugerir fluxo)
            if "[PIPELINE:" in full_response:
                import re
                pipe_match = re.search(r"\[PIPELINE:\s*(.*?)\]", full_response, re.IGNORECASE)
                if pipe_match:
                    agents_list = [a.strip().lower() for a in pipe_match.group(1).split(",")]
                    result_obj["pipeline"] = agents_list
                    # Atualiza o resultado no DB com o pipeline
                    await prisma.execution.update(
                        where={"id": execution.id},
                        data={"result": Json(result_obj)}
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
