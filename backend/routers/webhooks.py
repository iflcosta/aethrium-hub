from fastapi import APIRouter, Request
from integrations.discord import (
    notify_task_completed,
    notify_urgent,
    notify_system_deployed,
    notify_server_status
)
from integrations.vision import analyze_map_image, analyze_map_from_base64
import json
from pydantic import BaseModel
from typing import Optional

router = APIRouter(prefix="/webhooks", tags=["Webhooks"])

@router.post("/n8n/task-completed")
async def webhook_task_completed(request: Request):
    """Called by n8n when a task is completed"""
    body = await request.json()
    await notify_task_completed(
        task_title=body.get("task_title", "Task"),
        agent=body.get("agent", "Unknown"),
        delivery=body.get("delivery", "")
    )
    return {"status": "notified"}

@router.post("/n8n/server-status")
async def webhook_server_status(request: Request):
    """Called by n8n when server status changes"""
    body = await request.json()
    await notify_server_status(
        status=body.get("status", "unknown"),
        details=body.get("details", "")
    )
    return {"status": "notified"}

@router.post("/n8n/vip-activated")
async def webhook_vip_activated(request: Request):
    """Called by n8n when a player activates VIP"""
    body = await request.json()
    player = body.get("player_name", "Unknown")
    tier = body.get("tier", "Bronze")
    await notify_task_completed(
        task_title=f"VIP {tier} Ativado",
        agent="sistema",
        delivery=f"Jogador **{player}** ativou o plano VIP {tier}."
    )
    return {"status": "notified"}

@router.post("/test/sandbox")
async def test_sandbox():
    """Test E2B Sandbox connectivity"""
    from integrations.sandbox import run_lua_test
    result = await run_lua_test('print("Hello from E2B Sandbox!")', "Connectivity Test")
    return result

@router.post("/test/discord")
async def test_discord(request: Request):
    """Test Discord notification"""
    import os
    from integrations.discord import send_discord_notification, send_to_channel
    
    # Check what is configured
    has_webhook = bool(os.getenv("DISCORD_WEBHOOK_URL"))
    has_token = bool(os.getenv("DISCORD_TOKEN"))
    
    if not has_webhook and not has_token:
        return {"status": "error", "message": "Nem o Webhook nem o Bot Token estão configurados no Render."}
        
    messages_sent = []
    
    # Test Webhook if available
    if has_webhook:
        await send_discord_notification(
            title="🧪 Teste do Aethrium Hub (Webhook)",
            message="O Webhook padrão está funcionando corretamente!",
            color=0x7F77DD
        )
        messages_sent.append("Webhook")
        
    # We cannot automatically test the Token without knowing a Target Channel ID.
    # But we can return success if the Token is loaded in the env vars!
    if has_token:
        messages_sent.append("Bot Token (Verificado nas Variáveis)")
        
    return {
        "status": "ok", 
        "message": f"Teste validado para: {', '.join(messages_sent)}",
        "has_token": has_token,
        "has_webhook": has_webhook
    }
class VisionRequest(BaseModel):
    image_base64: Optional[str] = None
    image_path: Optional[str] = None
    question: Optional[str] = None

@router.post("/vision/analyze")
async def vision_analyze(req: VisionRequest):
    """Analyze a map image"""
    if req.image_path:
        return await analyze_map_image(req.image_path, req.question)
    elif req.image_base64:
        return await analyze_map_from_base64(req.image_base64, req.question)
    return {"status": "error", "message": "No image provided"}
