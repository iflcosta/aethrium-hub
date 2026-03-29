import httpx
import os
import time
from datetime import datetime
from utils import log_event

# Simple cooldown: at most 1 Discord message per 10 seconds
_last_sent_at: float = 0.0
_last_sent_to_channel_at: float = 0.0
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
                log_event(f"[DISCORD] Webhook delivery failed: {response.status_code} — {response.text[:200]}")
            else:
                log_event(f"[DISCORD] Notification sent (Webhook): {title}")
        except Exception as e:
            log_event(f"[DISCORD] Webhook connection error: {e}")

async def send_to_channel(channel_identifier: str, message: str, agent_slug: str = None, task_id: str = None):
    """Send a message to a specific Discord channel using Bot Token."""
    global _last_sent_to_channel_at
    from tools.prisma_tools import log_agent_event
    
    DISCORD_TOKEN = os.getenv("DISCORD_TOKEN")
    if not DISCORD_TOKEN:
        log_event("[DISCORD] Bot Token not configured, falling back to webhook.")
        await send_discord_notification(f"Message from {agent_slug or 'System'}", message, agent=agent_slug)
        return

    now = time.monotonic()
    if now - _last_sent_to_channel_at < _COOLDOWN_SECONDS:
        warn_msg = f"[DISCORD] Bot Cooldown active ({_COOLDOWN_SECONDS}s), skipping message to {channel_identifier}"
        log_event(warn_msg)
        if task_id and agent_slug:
            await log_agent_event(agent_slug, task_id, "discord_cooldown_skipped", {"channel": channel_identifier})
        return
    _last_sent_to_channel_at = now

    channel_id = channel_identifier.strip().replace("#", "")
    if not channel_id.isdigit():
        err_msg = f"[DISCORD] Channel ID invalid: '{channel_identifier}'. Attempting webhook fallback."
        log_event(err_msg)
        if task_id and agent_slug:
            await log_agent_event(agent_slug, task_id, "discord_invalid_channel", {"channel": channel_identifier})
        await send_discord_notification(f"To #{channel_identifier}", message, agent=agent_slug)
        return

    url = f"https://discord.com/api/v10/channels/{channel_id}/messages"
    headers = {
        "Authorization": f"Bot {DISCORD_TOKEN}",
        "Content-Type": "application/json"
    }
    
    agent_name = agent_slug # Fallback to slug if name not provided
    content = f"**[{agent_name}]**\n{message}" if agent_name else message
    payload = {"content": content}

    async with httpx.AsyncClient() as client:
        try:
            response = await client.post(url, json=payload, headers=headers)
            if response.status_code == 429:
                retry_after = response.headers.get("Retry-After", "unknown")
                err_log = f"[DISCORD] Bot Rate limited (429) for channel {channel_id}. Retry after {retry_after}s. Response: {response.text[:100]}"
                log_event(err_log)
                if task_id and agent_slug:
                    await log_agent_event(agent_slug, task_id, "discord_rate_limited", {"channel": channel_id, "retry_after": retry_after})
            elif response.status_code not in [200, 204]:
                err_log = f"[DISCORD] Bot delivery failed for channel {channel_id}: {response.status_code} — {response.text[:200]}"
                log_event(err_log)
                if task_id and agent_slug:
                    await log_agent_event(agent_slug, task_id, "discord_delivery_failed", {"channel": channel_id, "status": response.status_code, "error": response.text[:200]})
            else:
                log_event(f"[DISCORD] Message sent to channel {channel_id}")
                if task_id and agent_slug:
                    await log_agent_event(agent_slug, task_id, "discord_sent", {"channel": channel_id})
        except Exception as e:
            err_log = f"[DISCORD] Bot connection error for channel {channel_id}: {e}"
            log_event(err_log)
            if task_id and agent_slug:
                await log_agent_event(agent_slug, task_id, "discord_connection_error", {"channel": channel_id, "error": str(e)})

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
