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

            # Agent Memory Hook (all agents) — load persistent scratchpad before LLM
            agent_memory_context = ""
            _agent_db_for_memory = None
            try:
                _agent_db_for_memory = await prisma.agent.find_unique(where={"slug": self.slug})
                if _agent_db_for_memory and getattr(_agent_db_for_memory, "memory", None):
                    memory_data = _agent_db_for_memory.memory
                    if isinstance(memory_data, dict) and memory_data:
                        import json as _jmem
                        agent_memory_context = (
                            f"\n\n--- MEMÓRIA PERSISTENTE ({self.display_name}) ---\n"
                            "Informações que você aprendeu em tarefas anteriores:\n"
                            f"{_jmem.dumps(memory_data, ensure_ascii=False, indent=2)}\n"
                            "Use para evitar retrabalho. Adicione novos aprendizados com [MEMORY: chave = valor].\n"
                        )
            except Exception as e:
                print(f"[MEMORY] Load failed for {self.slug}: {e}")

            # Render Status Hook (Amanda) — fetch real infra status before LLM
            render_status_context = ""
            if self.slug == "amanda":
                try:
                    from integrations.render_api import get_infra_status_report
                    render_status_context = await get_infra_status_report()
                except Exception as e:
                    print(f"[RENDER] Status fetch failed: {e}")

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

            # Web Search Hook (Leonardo) — runs before LLM so findings enrich the response
            web_search_context = ""
            if self.slug == "leonardo" and prompt:
                try:
                    from integrations.web_search import search_otserv_topics
                    web_search_context = await search_otserv_topics(prompt)
                    if web_search_context:
                        print(f"[WEB_SEARCH] Injected {len(web_search_context)} chars for Leonardo")
                except Exception as e:
                    print(f"[WEB_SEARCH] Failed: {e}")

            # Procedural Map Generator Hook (Beatriz)
            map_spec_context = ""
            if self.slug == "beatriz":
                map_cfg = context.get("map_config")
                if map_cfg:
                    try:
                        from tools.map_generator import generate_map
                        spec = generate_map(
                            width=map_cfg.get("width", 60),
                            height=map_cfg.get("height", 40),
                            dungeon_type=map_cfg.get("type", "dungeon"),
                            floor_z=map_cfg.get("z", 7),
                            seed=map_cfg.get("seed"),
                        )
                        import json as _json
                        map_spec_context = (
                            f"\n\n--- MAPA PROCEDURAL GERADO (BSP) ---\n"
                            f"Tipo: {spec['type']} | Dimensões: {spec['dimensions']['width']}x{spec['dimensions']['height']} | Z: {spec['dimensions']['z']}\n"
                            f"Quartos: {spec['stats']['total_rooms']} | Corredores: {spec['stats']['total_corridors']} | Spawns: {spec['stats']['total_spawns']}\n\n"
                            f"ASCII Layout:\n{spec['ascii']}\n\n"
                            f"Spec JSON (quartos e AIDs):\n{_json.dumps({'rooms': spec['rooms'], 'aids': spec['aids'], 'spawns': spec['spawns'], 'teleports': spec['teleports']}, indent=2)}\n\n"
                            f"Notas RME: {spec['rme_notes']}\n"
                        )
                        print(f"[MAP_GEN] Generated {spec['type']} map with {spec['stats']['total_rooms']} rooms for Beatriz")
                    except Exception as e:
                        print(f"[MAP_GEN] Failed: {e}")

            enhanced_system = (
                self.system_prompt
                + rag_context
                + vision_analysis
                + file_context
                + image_gen_result
                + web_search_context
                + map_spec_context
                + agent_memory_context
                + render_status_context
            )

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

            # GitHub Push Hook (Rafael + Viktor) — only when context has push_to_github=True
            if self.slug in ("rafael", "viktor") and context.get("push_to_github"):
                task_title = context.get("title", f"Task {task_id[:8]}")

                if self.slug == "rafael" and "```lua" in full_response:
                    lua_blocks = re.findall(r"```lua\n(.*?)\n```", full_response, re.DOTALL)
                    file_match = re.search(
                        r"\[ARQUIVO\]\s*:?\s*`?([^\s`\n]+\.lua)`?", full_response, re.IGNORECASE
                    )
                    if lua_blocks:
                        from integrations.github_tools import push_lua_file
                        file_path_lua = (
                            file_match.group(1) if file_match
                            else f"data/scripts/rafael_{task_id[:8]}.lua"
                        )
                        gh_res = await push_lua_file(
                            file_path=file_path_lua,
                            lua_code=lua_blocks[0],
                            task_id=task_id,
                            task_title=task_title,
                        )
                        if gh_res.get("status") == "success":
                            gh_text = (
                                f"\n\n--- GITHUB PR CRIADO ---\n"
                                f"🔗 PR: {gh_res['pr_url']}\n"
                                f"🌿 Branch: `{gh_res['branch']}`\n"
                                f"📄 Arquivo: `{gh_res['file_path']}`\n"
                            )
                        else:
                            gh_text = f"\n\n⚠️ GitHub push falhou: {gh_res.get('message')}\n"
                        full_response += gh_text
                        yield f"data: {json.dumps({'seq': len(chunks)+1, 'chunk': gh_text, 'ts': ''})}\n\n"

                elif self.slug == "viktor" and "```cpp" in full_response:
                    cpp_blocks = re.findall(r"```cpp\n(.*?)\n```", full_response, re.DOTALL)
                    file_match = re.search(
                        r"\[ARQUIVO\]\s*:?\s*`?([^\s`\n]+\.(cpp|h|c|hpp))`?", full_response, re.IGNORECASE
                    )
                    if cpp_blocks:
                        from integrations.github_tools import push_cpp_file
                        file_path_cpp = (
                            file_match.group(1) if file_match
                            else f"patches/viktor_{task_id[:8]}.patch"
                        )
                        gh_res = await push_cpp_file(
                            file_path=file_path_cpp,
                            cpp_code=cpp_blocks[0],
                            task_id=task_id,
                            task_title=task_title,
                        )
                        if gh_res.get("status") == "success":
                            gh_text = (
                                f"\n\n--- GITHUB PR CRIADO ---\n"
                                f"🔗 PR: {gh_res['pr_url']}\n"
                                f"🌿 Branch: `{gh_res['branch']}`\n"
                                f"📄 Arquivo: `{gh_res['file_path']}`\n"
                            )
                        else:
                            gh_text = f"\n\n⚠️ GitHub push falhou: {gh_res.get('message')}\n"
                        full_response += gh_text
                        yield f"data: {json.dumps({'seq': len(chunks)+1, 'chunk': gh_text, 'ts': ''})}\n\n"

            # Render Redeploy Hook (Amanda) — fires when she writes [REDEPLOY: <service>]
            if self.slug == "amanda" and "[REDEPLOY:" in full_response:
                redeploy_targets = re.findall(r"\[REDEPLOY:\s*([^\]]+?)\]", full_response, re.IGNORECASE)
                for svc_name in redeploy_targets:
                    from integrations.render_api import trigger_deploy
                    rd_res = await trigger_deploy(svc_name.strip())
                    if rd_res.get("status") == "triggered":
                        rd_text = f"\n🚀 Redeploy iniciado: **{svc_name.strip()}** (deploy_id: `{rd_res.get('deploy_id', 'N/A')}`)\n"
                        from integrations.discord import notify_system_deployed
                        await notify_system_deployed(svc_name.strip())
                    else:
                        rd_text = f"\n❌ Redeploy falhou para **{svc_name.strip()}**: {rd_res.get('message')}\n"
                    full_response += rd_text
                    yield f"data: {json.dumps({'seq': len(chunks)+2, 'chunk': rd_text, 'ts': ''})}\n\n"

            # Leonardo RAG Write Hook — index [INDEXAR] block findings into Pinecone
            if self.slug == "leonardo" and "[INDEXAR]" in full_response:
                try:
                    indexar_match = re.search(r"\[INDEXAR\](.*?)(?=\[|$)", full_response, re.DOTALL | re.IGNORECASE)
                    if indexar_match:
                        finding_text = indexar_match.group(1).strip()
                        if finding_text and project_slug:
                            import time as _time
                            from rag.pinecone_client import PineconeClient
                            chunk_id = f"{project_slug}:leonardo:research:{int(_time.time())}"
                            chunks_to_index = [{
                                "id": chunk_id,
                                "text": finding_text,
                                "metadata": {
                                    "source": f"research/{task_id}",
                                    "project": project_slug,
                                    "agent": "leonardo",
                                    "type": "research_finding",
                                    "chunk_index": 0,
                                },
                            }]
                            await asyncio.to_thread(PineconeClient().upsert_chunks, chunks_to_index)
                            print(f"[RAG_WRITE] Leonardo indexed finding: {chunk_id}")
                except Exception as e:
                    print(f"[RAG_WRITE] Leonardo indexing failed: {e}")

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

            # Agent Memory Update Hook (all agents) — persist [MEMORY: key = value] blocks
            if "[MEMORY:" in full_response:
                try:
                    memory_updates = re.findall(
                        r"\[MEMORY:\s*([^=\]\n]+?)\s*=\s*([^\]\n]+?)\]",
                        full_response,
                        re.IGNORECASE,
                    )
                    if memory_updates:
                        agent_db_mem = _agent_db_for_memory or await prisma.agent.find_unique(where={"slug": self.slug})
                        if agent_db_mem:
                            current_memory = {}
                            raw_mem = getattr(agent_db_mem, "memory", None)
                            if isinstance(raw_mem, dict):
                                current_memory = raw_mem
                            for key, value in memory_updates:
                                current_memory[key.strip()] = value.strip()
                            await prisma.agent.update(
                                where={"slug": self.slug},
                                data={"memory": Json(current_memory)},
                            )
                            print(f"[MEMORY] {self.slug} updated: {[k for k, _ in memory_updates]}")
                except Exception as e:
                    print(f"[MEMORY] Update failed for {self.slug}: {e}")

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
