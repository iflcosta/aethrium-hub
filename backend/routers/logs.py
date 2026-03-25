import asyncio
import json
from datetime import datetime
from fastapi import APIRouter, Request
from sse_starlette.sse import EventSourceResponse
from utils import DEBUG_LOGS

router = APIRouter(prefix="/logs", tags=["Logs"])

@router.get("/stream")
async def stream_logs(request: Request):
    async def event_generator():
        last_log_index = len(DEBUG_LOGS)
        
        # Enviar últimos 10 logs imediatamente ao conectar
        start_idx = max(0, last_log_index - 10)
        for i in range(start_idx, last_log_index):
            yield {
                "data": json.dumps({
                    "timestamp": datetime_from_log(DEBUG_LOGS[i]),
                    "type": "SYSTEM",
                    "message": DEBUG_LOGS[i]
                })
            }

        while True:
            if await request.is_disconnected():
                break

            if len(DEBUG_LOGS) > last_log_index:
                for i in range(last_log_index, len(DEBUG_LOGS)):
                    yield {
                        "data": json.dumps({
                            "timestamp": datetime_from_log(DEBUG_LOGS[i]),
                            "type": "SYSTEM",
                            "message": DEBUG_LOGS[i]
                        })
                    }
                last_log_index = len(DEBUG_LOGS)

            await asyncio.sleep(1)

    return EventSourceResponse(event_generator())

def datetime_from_log(log_str: str) -> str:
    # Extracts [timestamp] from "[2026-03-25T...] Message"
    try:
        if log_str.startswith("["):
            return log_str.split("]")[0][1:]
    except Exception:
        pass
    from datetime import datetime
    return datetime.now().isoformat()
