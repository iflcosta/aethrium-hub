import httpx
import os
import time
from datetime import datetime
from utils import log_event

# Simple cooldown: at most 1 Discord message per 10 seconds
_last_sent_at: float = 0.0
_COOLDOWN_SECONDS = 10

async def send_discord_notification(
    title: str,
    message: str,
    color: int = 0x7F77DD,
    agent: str = None
):
    """Send a rich embed notification to Discord"""
    global _last_sent_at
    # Read URL at call time so Render env vars are always picked up
    DISCORD_WEBHOOK_URL = os.getenv("DISCORD_WEBHOOK_URL")
    if not DISCORD_WEBHOOK_URL:
        log_event("[DISCORD] Webhook URL not configured")
        return

    now = time.monotonic()
    if now - _last_sent_at < _COOLDOWN_SECONDS:
        log_event(f"[DISCORD] Cooldown active ({_COOLDOWN_SECONDS}s), skipping: {title}")
        return
    _last_sent_at = now

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
    if agent:
        payload["username"] = agent
    else:
        payload["username"] = "Aethrium Studio"

    async with httpx.AsyncClient() as client:
        try:
            response = await client.post(DISCORD_WEBHOOK_URL, json=payload)
            if response.status_code == 429:
                retry_after = response.headers.get("Retry-After", "unknown")
                log_event(f"[DISCORD] Rate limited (429). Retry after {retry_after}s.")
            elif response.status_code not in [200, 204]:
                log_event(f"[DISCORD] Failed to send: {response.status_code} — {response.text[:200]}")
            else:
                log_event(f"[DISCORD] Notification sent: {title}")
        except Exception as e:
            log_event(f"[DISCORD] Connection error: {e}")

async def send_to_channel(channel_identifier: str, message: str, agent: str = None):
    """Send a message to a specific Discord channel using Bot Token."""
    DISCORD_TOKEN = os.getenv("DISCORD_TOKEN")
    if not DISCORD_TOKEN:
        log_event("[DISCORD] Bot Token not configured, falling back to webhook.")
        await send_discord_notification(f"Message from {agent or 'System'}", message, agent=agent)
        return

    # In a real scenario, you'd map channel_identifier (name) to a numeric ID using DISCORD_GUILD_ID.
    # For simplicity, if it's not numeric, we log a warning unless we implement the fetch logic.
    # We will assume channel_identifier is the channel ID for now, or just send to webhook if not.
    channel_id = channel_identifier.strip().replace("#", "")
    if not channel_id.isdigit():
        # Fallback if it's a name and we don't have the mapping yet
        log_event(f"[DISCORD] Channel name resolution not implemented. Attempting webhook fallback for {channel_identifier}.")
        await send_discord_notification(f"To #{channel_identifier}", message, agent=agent)
        return

    url = f"https://discord.com/api/v10/channels/{channel_id}/messages"
    headers = {
        "Authorization": f"Bot {DISCORD_TOKEN}",
        "Content-Type": "application/json"
    }
    
    content = f"**[{agent}]**\n{message}" if agent else message
    payload = {"content": content}

    async with httpx.AsyncClient() as client:
        try:
            response = await client.post(url, json=payload, headers=headers)
            if response.status_code not in [200, 204]:
                log_event(f"[DISCORD] Failed to send to channel {channel_id}: {response.status_code} — {response.text[:200]}")
            else:
                log_event(f"[DISCORD] Message sent to channel {channel_id}")
        except Exception as e:
            log_event(f"[DISCORD] Connection error: {e}")

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
