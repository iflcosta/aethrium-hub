import asyncio
from datetime import datetime, date

running = False

# Tracks last run per job key to avoid duplicate runs
_last_runs: dict = {}


async def _run_agent_job(slug: str, title: str, prompt: str):
    """Creates a Task + Execution and runs the agent autonomously."""
    from db import prisma
    from graphs.studio_graph import agents
    from prisma import Json

    if slug not in agents:
        print(f"[SCHEDULER] Agent '{slug}' not registered, skipping")
        return

    agent = agents[slug]

    agent_db = await prisma.agent.find_unique(where={"slug": slug})
    if not agent_db:
        agent_db = await prisma.agent.find_unique(where={"slug": "carlos"})
    if not agent_db:
        print(f"[SCHEDULER] No agent record in DB for '{slug}', skipping")
        return

    task = await prisma.task.create(data={
        "title": title,
        "description": f"Tarefa autônoma agendada — {slug}",
        "ownerId": agent_db.id,
        "status": "RUNNING",
        "priority": 1,
    })

    execution = await prisma.execution.create(data={
        "taskId": task.id,
        "agentSlug": slug,
        "model": agent.model,
        "promptTokens": 0,
        "compTokens": 0,
        "thoughtChunks": Json([]),
    })

    print(f"[SCHEDULER] ▶ {slug} | task={task.id} | {title}")
    try:
        async for _ in agent.run(task.id, {
            "prompt": prompt,
            "execution_id": execution.id,
            "scheduled": True,
        }):
            pass
        print(f"[SCHEDULER] ✓ {slug} completed task {task.id}")
    except Exception as e:
        print(f"[SCHEDULER] ✗ {slug} failed: {e}")


def _should_run(key: str, weekdays: list) -> bool:
    """True if today matches weekdays and job hasn't run today yet."""
    today = date.today()
    if today.weekday() not in weekdays:
        return False
    if _last_runs.get(key) == str(today):
        return False
    _last_runs[key] = str(today)
    return True


def _should_run_window(key: str, interval_minutes: int) -> bool:
    """True if interval_minutes have passed since last run."""
    now = datetime.utcnow()
    window = f"{now.date()}-{now.hour}-{now.minute // interval_minutes}"
    if _last_runs.get(key) == window:
        return False
    _last_runs[key] = window
    return True


# ─── Job definitions ────────────────────────────────────────────────────────

async def _job_leonardo_research():
    """Leonardo: market research — Mon / Wed / Fri at 09:00 UTC."""
    now = datetime.utcnow()
    if now.hour != 9:
        return
    if not _should_run("leonardo_research", weekdays=[0, 2, 4]):
        return
    await _run_agent_job(
        slug="leonardo",
        title=f"Pesquisa de mercado autônoma — {now.strftime('%d/%m/%Y')}",
        prompt=(
            "Faça uma pesquisa de mercado semanal sobre o ecossistema OTServ. "
            "Responda nos seguintes blocos:\n\n"
            "[PESQUISA] Quais servidores estão mais ativos esta semana e por quê?\n"
            "[COMPARATIVO] Que sistemas/features novos servidores concorrentes lançaram recentemente?\n"
            "[MONETIZAÇÃO] Quais estratégias de VIP/loja/donate estão funcionando melhor?\n"
            "[RECOMENDAÇÃO] Uma feature concreta para implementar no Baiak Thunder esta semana, "
            "com justificativa baseada no mercado.\n\n"
            "Seja direto e prático. Priorize informações acionáveis."
        ),
    )


async def _job_lucas_weekly_content():
    """Lucas: weekly social content pack — Monday at 10:00 UTC."""
    now = datetime.utcnow()
    if now.hour != 10:
        return
    if not _should_run("lucas_weekly_content", weekdays=[0]):
        return
    await _run_agent_job(
        slug="lucas",
        title=f"Pacote de conteúdo semanal — {now.strftime('%d/%m/%Y')}",
        prompt=(
            "Crie o pacote de conteúdo semanal do Baiak Thunder para Discord e redes sociais. "
            "Produza os seguintes itens:\n\n"
            "[POST DE ABERTURA] Mensagem de boas-vindas à semana, novidades e eventos previstos.\n"
            "[DICA DA SEMANA] Uma dica de gameplay útil para jogadores (iniciantes ou veteranos).\n"
            "[TEASER] Um teaser curto e intrigante sobre uma feature em desenvolvimento.\n"
            "[CALL-TO-ACTION] Uma chamada para engajamento (votação, evento, recrutamento de jogadores).\n\n"
            "Tom: animado, direto, em português BR. Cada bloco pronto para copiar e colar."
        ),
    )


async def _job_amanda_infra_check():
    """Amanda: infrastructure audit — daily at 08:00 UTC."""
    now = datetime.utcnow()
    if now.hour != 8:
        return
    if not _should_run("amanda_infra_check", weekdays=[0, 1, 2, 3, 4, 5, 6]):
        return
    await _run_agent_job(
        slug="amanda",
        title=f"Auditoria de infraestrutura — {now.strftime('%d/%m/%Y')}",
        prompt=(
            "Faça uma auditoria diária da infraestrutura do Aethrium Studio. "
            "Avalie cada item e produza um relatório:\n\n"
            "[INFRAESTRUTURA] Status dos serviços:\n"
            "- Backend API: https://aethrium-hub.onrender.com/health\n"
            "- Frontend: https://aethrium-hub.vercel.app\n"
            "- Banco de dados: Supabase PostgreSQL\n"
            "- Vector DB: Pinecone (index: aethrium-studio)\n"
            "- OTServ Baiak Thunder: offline (ainda não lançado)\n\n"
            "[AÇÕES PREVENTIVAS] O que deve ser feito hoje para evitar problemas?\n"
            "[ALERTAS] Algum risco ou gargalo identificado?\n\n"
            "Se tudo estiver saudável, conclua com [INFRAESTRUTURA OK]. "
            "Se houver problema crítico, comece a resposta com [URGENTE]."
        ),
    )


# ─── Scheduler loop ──────────────────────────────────────────────────────────

SCHEDULED_JOBS = [
    _job_leonardo_research,
    _job_lucas_weekly_content,
    _job_amanda_infra_check,
]


async def schedule_loop():
    global running
    print("[SCHEDULER] Started — checking jobs every 60s")

    # Wait for DB/app to finish initializing
    await asyncio.sleep(15)

    while running:
        now = datetime.utcnow()
        for job in SCHEDULED_JOBS:
            try:
                asyncio.create_task(job())
            except Exception as e:
                print(f"[SCHEDULER] Error dispatching {job.__name__}: {e}")
        await asyncio.sleep(60)

    print("[SCHEDULER] Stopped")


def start_scheduler():
    global running
    if not running:
        running = True
        asyncio.create_task(schedule_loop())


def stop_scheduler():
    global running
    running = False


# ─── Status / manual trigger (used by API) ───────────────────────────────────

def get_scheduler_status() -> dict:
    return {
        "running": running,
        "jobs": [
            {
                "key": "leonardo_research",
                "agent": "leonardo",
                "schedule": "Mon / Wed / Fri at 09:00 UTC",
                "last_run": _last_runs.get("leonardo_research"),
            },
            {
                "key": "lucas_weekly_content",
                "agent": "lucas",
                "schedule": "Monday at 10:00 UTC",
                "last_run": _last_runs.get("lucas_weekly_content"),
            },
            {
                "key": "amanda_infra_check",
                "agent": "amanda",
                "schedule": "Daily at 08:00 UTC",
                "last_run": _last_runs.get("amanda_infra_check"),
            },
        ],
    }


async def trigger_job(key: str) -> dict:
    """Manually trigger a scheduled job by key (ignores time/day guards)."""
    now = datetime.utcnow()
    jobs = {
        "leonardo_research": lambda: _run_agent_job(
            slug="leonardo",
            title=f"Pesquisa de mercado (manual) — {now.strftime('%d/%m/%Y %H:%M')} UTC",
            prompt=(
                "Faça uma pesquisa de mercado sobre o ecossistema OTServ. "
                "[PESQUISA] Servidores mais ativos agora. "
                "[COMPARATIVO] Features recentes de concorrentes. "
                "[MONETIZAÇÃO] O que está funcionando. "
                "[RECOMENDAÇÃO] Uma feature concreta para o Baiak Thunder."
            ),
        ),
        "lucas_weekly_content": lambda: _run_agent_job(
            slug="lucas",
            title=f"Conteúdo semanal (manual) — {now.strftime('%d/%m/%Y %H:%M')} UTC",
            prompt=(
                "Crie um pacote de conteúdo para o Baiak Thunder: "
                "[POST DE ABERTURA] Boas-vindas e novidades. "
                "[DICA DA SEMANA] Uma dica de gameplay. "
                "[TEASER] Feature em desenvolvimento. "
                "[CALL-TO-ACTION] Chamada de engajamento."
            ),
        ),
        "amanda_infra_check": lambda: _run_agent_job(
            slug="amanda",
            title=f"Auditoria de infraestrutura (manual) — {now.strftime('%d/%m/%Y %H:%M')} UTC",
            prompt=(
                "Auditoria imediata da infraestrutura Aethrium Studio. "
                "[INFRAESTRUTURA] Status de todos os serviços. "
                "[AÇÕES PREVENTIVAS] O que fazer agora. "
                "[ALERTAS] Riscos identificados. "
                "Se tudo ok: [INFRAESTRUTURA OK]. Se crítico: comece com [URGENTE]."
            ),
        ),
    }
    if key not in jobs:
        return {"error": f"Job '{key}' not found"}
    asyncio.create_task(jobs[key]())
    return {"status": "triggered", "job": key}
