import asyncio
import json
from fastapi import APIRouter, Request
from sse_starlette.sse import EventSourceResponse
from db import prisma

router = APIRouter(prefix="/stream", tags=["Stream"])

@router.get("/{execution_id}")
async def stream_execution(execution_id: str, request: Request):
    async def event_generator():
        last_chunk_index = 0
        final_delivery = ""
        
        while True:
            if await request.is_disconnected():
                break
                
            execution = await prisma.execution.find_unique(where={"id": execution_id})
            if not execution:
                yield {"data": json.dumps({"seq": 0, "delta": "Execution not found.", "agent": "system", "ts": ""})}
                break
                
            try:
                chunks = json.loads(execution.thoughtChunks) if execution.thoughtChunks else []
            except:
                chunks = []
                
            for i in range(last_chunk_index, len(chunks)):
                chunk_data = {"seq": i, "delta": chunks[i], "agent": execution.agentSlug if hasattr(execution, 'agentSlug') and execution.agentSlug else "agent", "ts": str(execution.startedAt)}
                print(f"[SSE] Sending chunk {i} for {execution_id}")
                yield {"data": json.dumps(chunk_data)}
                
            last_chunk_index = len(chunks)
            
            if execution.status in ["COMPLETED", "FAILED"] or execution.finishedAt:
                # Ensure we drain any final chunks that arrived between last find and status check
                execution = await prisma.execution.find_unique(where={"id": execution_id})
                try:
                    final_chunks = json.loads(execution.thoughtChunks) if execution.thoughtChunks else []
                except:
                    final_chunks = []
                
                for i in range(last_chunk_index, len(final_chunks)):
                    chunk_data = {"seq": i, "delta": final_chunks[i], "agent": execution.agentSlug, "ts": str(execution.startedAt)}
                    print(f"[SSE] Sending final chunk {i} for {execution_id}")
                    yield {"data": json.dumps(chunk_data)}

                # In Meeting mode or Carlos gatekeeper, result might contain final delivery
                if execution.result:
                    try:
                        res_obj = json.loads(execution.result) if isinstance(execution.result, str) else execution.result
                        # Prefer "text" as per new BaseAgent logic, fallback to "final_delivery"
                        final_delivery = res_obj.get("text") or res_obj.get("final_delivery", "")
                    except:
                        final_delivery = "".join(final_chunks)
                else:
                    # Fallback to join the chunks if it's a single agent run
                    final_delivery = "".join(final_chunks)

                print(f"[SSE] Sending done for {execution_id}. Length: {len(final_delivery)}")
                yield {"data": json.dumps({"type": "done", "final_delivery": final_delivery})}
                break
                
            await asyncio.sleep(0.5)

    return EventSourceResponse(event_generator(), headers={"Access-Control-Allow-Origin": "http://localhost:3000"})
