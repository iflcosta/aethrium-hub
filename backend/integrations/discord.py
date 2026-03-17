import httpx
import os
from datetime import datetime

DISCORD_WEBHOOK_URL = os.getenv("DISCORD_WEBHOOK_URL")

async def send_discord_notification(
    title: str,
    message: str,
    color: int = 0x7F77DD,
    agent: str = None
):
    """Send a rich embed notification to Discord"""
    if not DISCORD_WEBHOOK_URL:
        print("[DISCORD] Webhook URL not configured")
        return

    embed = {
        "title": title,
        "description": message,
        "color": color,
        "timestamp": datetime.utcnow().isoformat(),
        "footer": {"text": "Aethrium Studio"}
    }

    if agent:
        embed["author"] = {"name": f"Agente: {agent}"}

    payload = {"embeds": [embed]}

    async with httpx.AsyncClient() as client:
        try:
            response = await client.post(DISCORD_WEBHOOK_URL, json=payload)
            if response.status_code != 204:
                print(f"[DISCORD] Failed to send: {response.status_code}")
            else:
                print(f"[DISCORD] Notification sent: {title}")
        except Exception as e:
            print(f"[DISCORD] Connection error: {e}")

# Predefined notification types
async def notify_task_completed(task_title: str, agent: str, delivery: str):
    await send_discord_notification(
        title="✅ Task Concluída",
        message=f"**{task_title}**\n\n{delivery[:500]}...",
        color=0x1D9E75,
        agent=agent
    )

async def notify_urgent(message: str, agent: str):
    await send_discord_notification(
        title="⚠️ URGENTE",
        message=message,
        color=0xE24B4A,
        agent=agent
    )

async def notify_system_deployed(system_name: str):
    await send_discord_notification(
        title="🚀 Sistema Deployado",
        message=f"O sistema **{system_name}** foi deployado com sucesso no servidor.",
        color=0x378ADD
    )

async def notify_server_status(status: str, details: str = ""):
    color = 0x1D9E75 if status == "online" else 0xE24B4A
    await send_discord_notification(
        title=f"🖥️ Servidor {status.upper()}",
        message=details or f"O servidor está {status}.",
        color=color
    )
