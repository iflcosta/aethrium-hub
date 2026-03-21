import asyncio
import json
from fastapi import APIRouter, Request
from sse_starlette.sse import EventSourceResponse
from db import prisma

router = APIRouter(prefix="/stream", tags=["Stream"])


def _parse_chunks(value) -> list:
    """Safely parse thoughtChunks — Prisma returns Json fields as Python objects, not strings."""
    if value is None:
        return []
    if isinstance(value, list):
        return value
    if isinstance(value, str):
        try:
            parsed = json.loads(value)
            return parsed if isinstance(parsed, list) else []
        except Exception:
            return []
    return []


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

            chunks = _parse_chunks(execution.thoughtChunks)
            print(f"[STREAM] Chunks found: {len(chunks)} (sent so far: {last_chunk_index}) status={execution.status}")

            for i in range(last_chunk_index, len(chunks)):
                chunk_data = {
                    "seq": i,
                    "delta": chunks[i],
                    "agent": execution.agentSlug or "agent",
                    "ts": str(execution.startedAt),
                }
                print(f"[SSE] Sending chunk {i} for {execution_id}")
                yield {"data": json.dumps(chunk_data)}

            last_chunk_index = len(chunks)

            if execution.status in ["COMPLETED", "FAILED"] or execution.finishedAt:
                # Drain any final chunks that arrived between last poll and status check
                execution = await prisma.execution.find_unique(where={"id": execution_id})
                final_chunks = _parse_chunks(execution.thoughtChunks)

                for i in range(last_chunk_index, len(final_chunks)):
                    chunk_data = {
                        "seq": i,
                        "delta": final_chunks[i],
                        "agent": execution.agentSlug or "agent",
                        "ts": str(execution.startedAt),
                    }
                    print(f"[SSE] Sending final chunk {i} for {execution_id}")
                    yield {"data": json.dumps(chunk_data)}

                # Build final_delivery — prefer result.text, fall back to joined chunks
                if execution.result:
                    try:
                        res_obj = execution.result if isinstance(execution.result, dict) else json.loads(execution.result)
                        final_delivery = res_obj.get("text") or res_obj.get("final_delivery") or ""
                    except Exception:
                        final_delivery = ""

                if not final_delivery:
                    final_delivery = "".join(final_chunks)

                # Last-resort: if still empty after FAILED, signal the error
                if not final_delivery and execution.status == "FAILED":
                    error_msg = ""
                    try:
                        if hasattr(execution, "error") and execution.error:
                            error_msg = str(execution.error)
                    except Exception:
                        pass
                    final_delivery = f"[Erro do agente: {error_msg}]" if error_msg else "[Agente falhou sem mensagem de erro]"

                done_payload: dict = {"type": "done", "final_delivery": final_delivery}
                if execution.result:
                    try:
                        res_obj = execution.result if isinstance(execution.result, dict) else json.loads(execution.result)
                        if "handoff" in res_obj:
                            done_payload["handoff"] = res_obj["handoff"]
                    except Exception:
                        pass

                print(f"[SSE] Sending done for {execution_id}. Length: {len(final_delivery)}")
                yield {"data": json.dumps(done_payload)}
                break

            await asyncio.sleep(0.5)

    return EventSourceResponse(event_generator(), headers={"Access-Control-Allow-Origin": "*"})
