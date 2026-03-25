"""
Render.com API integration for Amanda (DevOps agent).
Provides real-time deploy status and the ability to trigger redeployments.

Required env vars:
  RENDER_API_KEY — Render API key (generate at dashboard.render.com → Account → API Keys)

Optional:
  RENDER_SERVICE_BACKEND  — Service ID for the backend (bypasses name lookup)
  RENDER_SERVICE_FRONTEND — Service ID for the frontend (bypasses name lookup)
"""

import os
import httpx
from typing import Optional

RENDER_API_KEY = os.getenv("RENDER_API_KEY", "")
RENDER_API_BASE = "https://api.render.com/v1"

# Known services (name fragments → IDs).  IDs are resolved once and cached.
_KNOWN_SERVICES = {
    "backend":  os.getenv("RENDER_SERVICE_BACKEND",  ""),
    "frontend": os.getenv("RENDER_SERVICE_FRONTEND", ""),
}
_service_id_cache: dict[str, str] = {}


# ─── Internal helpers ─────────────────────────────────────────────────────────

def _headers() -> dict:
    return {
        "Authorization": f"Bearer {RENDER_API_KEY}",
        "Accept":        "application/json",
        "Content-Type":  "application/json",
    }


async def _resolve_service_id(name_fragment: str) -> Optional[str]:
    """
    Resolve a service ID from env var first, then by name lookup from the API.
    Caches results to avoid repeat API calls.
    """
    name_lower = name_fragment.lower()

    if name_lower in _service_id_cache:
        return _service_id_cache[name_lower]

    # Check env var shortcuts
    for key, svc_id in _KNOWN_SERVICES.items():
        if key in name_lower and svc_id:
            _service_id_cache[name_lower] = svc_id
            return svc_id

    # Dynamic lookup
    if not RENDER_API_KEY:
        return None
    try:
        async with httpx.AsyncClient(timeout=10) as client:
            r = await client.get(f"{RENDER_API_BASE}/services?limit=30", headers=_headers())
            if r.status_code == 200:
                for item in r.json():
                    svc = item.get("service", item)
                    if name_lower in svc.get("name", "").lower():
                        svc_id = svc.get("id")
                        _service_id_cache[name_lower] = svc_id
                        return svc_id
    except Exception as e:
        print(f"[RENDER] Service lookup error: {e}")
    return None


# ─── Public API ───────────────────────────────────────────────────────────────

async def get_latest_deploy(service_name: str) -> dict:
    """
    Return the most recent deploy info for a service.
    """
    if not RENDER_API_KEY:
        return {"status": "unknown", "message": "RENDER_API_KEY não configurada"}

    svc_id = await _resolve_service_id(service_name)
    if not svc_id:
        return {"status": "unknown", "message": f"Serviço '{service_name}' não encontrado"}

    try:
        async with httpx.AsyncClient(timeout=10) as client:
            r = await client.get(
                f"{RENDER_API_BASE}/services/{svc_id}/deploys?limit=1",
                headers=_headers(),
            )
            if r.status_code == 200:
                deploys = r.json()
                if deploys:
                    d = deploys[0].get("deploy", deploys[0])
                    return {
                        "status":      d.get("status", "unknown"),
                        "created_at":  d.get("createdAt"),
                        "finished_at": d.get("finishedAt"),
                        "service_id":  svc_id,
                        "deploy_id":   d.get("id"),
                    }
        return {"status": "unknown"}
    except Exception as e:
        return {"status": "error", "message": str(e)}


async def trigger_deploy(service_name: str) -> dict:
    """
    Trigger a new deploy for a Render service.
    Amanda calls this when she writes [REDEPLOY: <service_name>] in her response.
    """
    if not RENDER_API_KEY:
        return {"status": "error", "message": "RENDER_API_KEY não configurada"}

    svc_id = await _resolve_service_id(service_name)
    if not svc_id:
        return {"status": "error", "message": f"Serviço '{service_name}' não encontrado"}

    try:
        async with httpx.AsyncClient(timeout=15) as client:
            r = await client.post(
                f"{RENDER_API_BASE}/services/{svc_id}/deploys",
                headers=_headers(),
                json={"clearCache": "do_not_clear"},
            )
            if r.status_code in (200, 201):
                d = r.json()
                deploy = d.get("deploy", d)
                return {
                    "status":    "triggered",
                    "deploy_id": deploy.get("id"),
                    "service":   service_name,
                    "service_id": svc_id,
                }
            return {"status": "error", "message": f"HTTP {r.status_code}: {r.text[:200]}"}
    except Exception as e:
        return {"status": "error", "message": str(e)}


async def get_infra_status_report() -> str:
    """
    Build a real-time infra status block for Amanda's context (pre-LLM injection).
    Returns formatted text; empty string if RENDER_API_KEY is not set.
    """
    if not RENDER_API_KEY:
        return ""

    services = ["backend", "frontend"]
    status_map = {
        "live":                "✅ live",
        "build_in_progress":   "🔄 build em progresso",
        "update_in_progress":  "🔄 deploy em progresso",
        "deactivated":         "💤 desativado",
        "suspended":           "⏸️ suspenso",
        "failed":              "❌ falhou",
        "unknown":             "❓ desconhecido",
    }

    lines = ["\n\n--- STATUS REAL DA INFRAESTRUTURA (Render API) ---"]
    for name in services:
        info = await get_latest_deploy(name)
        raw_status = info.get("status", "unknown")
        display    = status_map.get(raw_status, raw_status)
        lines.append(f"  • {name}: {display}")
        if info.get("finished_at"):
            lines.append(f"    Último deploy: {info['finished_at']}")
        if info.get("message"):
            lines.append(f"    ⚠️  {info['message']}")

    lines.append(
        "\nPara disparar um redeploy, use [REDEPLOY: backend] ou [REDEPLOY: frontend] na sua resposta."
    )
    return "\n".join(lines) + "\n"
