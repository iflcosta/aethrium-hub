import asyncio
from datetime import datetime, date

running = False

# Tracks last run per job key to avoid duplicate runs
_last_runs: dict = {}

# Active Studio projects — used to give agents multi-project context
STUDIO_PROJECTS = [
    {"slug": "aethrium-mmorpg",   "name": "Aethrium MMORPG",    "engine": "Canary",  "protocol": "custom"},
    {"slug": "baiak-thunder-86",  "name": "Baiak Thunder 8.6",   "engine": "TFS 1.5", "protocol": "8.60"},
    {"slug": "tibia-global",      "name": "Tibia Global 15+",    "engine": "Canary",  "protocol": "12+"},
    {"slug": "moba-otserv",       "name": "MOBA OTServ",         "engine": "Canary",  "protocol": "custom"},
    {"slug": "pvp-enforced",      "name": "PvP Enforced",        "engine": "TFS 1.5", "protocol": "8.60"},
]

def _projects_summary() -> str:
    lines = [f"  • {p['name']} ({p['engine']}, protocolo {p['protocol']})" for p in STUDIO_PROJECTS]
    return "\n".join(lines)


async def _run_agent_job(slug: str, title: str, prompt: str, context: dict = None):
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

    run_context = {"prompt": prompt, "execution_id": execution.id, "scheduled": True}
    if context:
        run_context.update(context)

    print(f"[SCHEDULER] ▶ {slug} | task={task.id} | {title}")
    try:
        async for _ in agent.run(task.id, run_context):
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

async def _job_carlos_backlog_sweep():
    """
    Carlos: autonomous backlog runner — every 30 minutes.
    Picks the highest-priority PENDING task and executes it through the full pipeline.
    This is the core of autonomous operation: no human needs to click 'Run'.
    """
    if not _should_run_window("carlos_backlog_sweep", interval_minutes=30):
        return

    from db import prisma

    # Find the highest-priority pending task that is NOT ephemeral chat
    pending = await prisma.task.find_many(
        where={"status": "PENDING", "isChat": False},
        order=[{"priority": "desc"}, {"createdAt": "asc"}],
        take=1,
        include={"owner": True, "project": True},
    )

    if not pending:
        print("[SCHEDULER] Carlos backlog sweep: no PENDING tasks, skipping")
        return

    task = pending[0]
    project_slug = None
    project_name = "Aethrium Hub"
    if task.project:
        project_slug = task.project.slug
        project_name = task.project.displayName

    print(f"[SCHEDULER] Carlos picking up task: '{task.title}' (priority={task.priority})")

    context = {
        "summary": task.description or task.title,
        "task_id": task.id,
        "scheduled": True,
        "autonomous": True,
    }
    if project_slug:
        context["project_slug"] = project_slug

    await _run_agent_job(
        slug="carlos",
        title=f"[AUTO] {task.title}",
        prompt=(
            f"Tarefa autônoma recebida do backlog:\n\n"
            f"**Título:** {task.title}\n"
            f"**Projeto:** {project_name}\n"
            f"**Descrição:** {task.description or '(sem descrição adicional)'}\n\n"
            f"Analise esta tarefa, execute ou delegue ao especialista correto via [PIPELINE: agente1, agente2]. "
            f"Se for uma tarefa de desenvolvimento, delegue ao especialista e peça o resultado completo."
        ),
        context=context,
    )

    # Mark the original task as RUNNING so it won't be picked up again
    await prisma.task.update(
        where={"id": task.id},
        data={"status": "RUNNING"},
    )


async def _job_leonardo_research():
    """Leonardo: market research across all Studio projects — Mon / Wed / Fri at 09:00 UTC."""
    now = datetime.utcnow()
    if now.hour != 9:
        return
    if not _should_run("leonardo_research", weekdays=[0, 2, 4]):
        return

    projects_list = _projects_summary()
    await _run_agent_job(
        slug="leonardo",
        title=f"Pesquisa de mercado autônoma — {now.strftime('%d/%m/%Y')}",
        prompt=(
            f"Faça uma pesquisa de mercado semanal para o Aethrium Hub. "
            f"O Studio tem os seguintes projetos ativos em desenvolvimento:\n{projects_list}\n\n"
            "[PESQUISA] Quais servidores do mesmo tipo estão mais ativos esta semana e por quê?\n"
            "[COMPARATIVO] Que sistemas/features novos servidores concorrentes lançaram recentemente?\n"
            "[MONETIZAÇÃO] Quais estratégias de VIP/loja/donate estão funcionando melhor para cada tipo de jogo?\n"
            "[RECOMENDAÇÃO] Uma feature concreta para cada projeto ativo, "
            "com justificativa baseada no mercado.\n\n"
            "Seja direto e prático. Priorize informações acionáveis para cada projeto."
        ),
    )


async def _job_lucas_weekly_content():
    """Lucas: weekly social content pack — Monday at 10:00 UTC."""
    now = datetime.utcnow()
    if now.hour != 10:
        return
    if not _should_run("lucas_weekly_content", weekdays=[0]):
        return

    projects_list = _projects_summary()
    await _run_agent_job(
        slug="lucas",
        title=f"Pacote de conteúdo semanal — {now.strftime('%d/%m/%Y')}",
        prompt=(
            f"Crie o pacote de conteúdo semanal do Aethrium Hub para Discord e redes sociais.\n"
            f"Projetos em desenvolvimento:\n{projects_list}\n\n"
            "[POST DE ABERTURA] Mensagem de boas-vindas à semana com novidades de todos os projetos.\n"
            "[DESTAQUE DA SEMANA] Escolha um projeto para destacar com maior detalhe (rotacione entre os projetos).\n"
            "[DICA DA SEMANA] Uma dica de gameplay útil para o projeto em destaque.\n"
            "[TEASER] Um teaser curto e intrigante sobre uma feature em desenvolvimento (pode ser qualquer projeto).\n"
            "[CALL-TO-ACTION] Uma chamada para engajamento da comunidade.\n\n"
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

    projects_list = _projects_summary()
    await _run_agent_job(
        slug="amanda",
        title=f"Auditoria de infraestrutura — {now.strftime('%d/%m/%Y')}",
        prompt=(
            f"Faça uma auditoria diária da infraestrutura do Aethrium Hub.\n"
            f"Projetos no Studio (todos em desenvolvimento, nenhum em produção ainda):\n{projects_list}\n\n"
            "[INFRAESTRUTURA] Status dos serviços da plataforma:\n"
            "- Backend API: https://aethrium-hub.onrender.com/health\n"
            "- Frontend: https://aethrium-hub.vercel.app\n"
            "- Banco de dados: Supabase PostgreSQL\n"
            "- Vector DB: Pinecone (index: aethrium-studio)\n\n"
            "[PLANEJAMENTO] Quais servidores de jogo precisam ser provisionados em breve "
            "e quais são os requisitos de infraestrutura para cada um?\n"
            "[AÇÕES PREVENTIVAS] O que deve ser feito hoje para evitar problemas?\n"
            "[ALERTAS] Algum risco ou gargalo identificado?\n\n"
            "Se tudo estiver saudável, conclua com [INFRAESTRUTURA OK]. "
            "Se houver problema crítico, comece a resposta com [URGENTE]."
        ),
    )


# ─── Scheduler loop ──────────────────────────────────────────────────────────

SCHEDULED_JOBS = [
    _job_carlos_backlog_sweep,   # Every 30 min — core autonomous runner
    _job_leonardo_research,      # Mon/Wed/Fri 09:00 UTC
    _job_lucas_weekly_content,   # Monday 10:00 UTC
    _job_amanda_infra_check,     # Daily 08:00 UTC
]


async def schedule_loop():
    global running
    print("[SCHEDULER] Started — checking jobs every 60s")

    # Wait for DB/app to finish initializing
    await asyncio.sleep(15)

    while running:
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
                "key": "carlos_backlog_sweep",
                "agent": "carlos",
                "schedule": "Every 30 minutes",
                "last_run": _last_runs.get("carlos_backlog_sweep"),
                "description": "Autonomous backlog runner — picks up PENDING tasks automatically",
            },
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
        "carlos_backlog_sweep": lambda: _job_carlos_backlog_sweep_force(),
        "leonardo_research": lambda: _run_agent_job(
            slug="leonardo",
            title=f"Pesquisa de mercado (manual) — {now.strftime('%d/%m/%Y %H:%M')} UTC",
            prompt=(
                f"Faça uma pesquisa de mercado sobre os projetos do Aethrium Hub.\n"
                f"Projetos: {_projects_summary()}\n"
                "[PESQUISA] Servidores mais ativos agora. "
                "[COMPARATIVO] Features recentes de concorrentes. "
                "[MONETIZAÇÃO] O que está funcionando. "
                "[RECOMENDAÇÃO] Uma feature concreta para cada projeto."
            ),
        ),
        "lucas_weekly_content": lambda: _run_agent_job(
            slug="lucas",
            title=f"Conteúdo semanal (manual) — {now.strftime('%d/%m/%Y %H:%M')} UTC",
            prompt=(
                f"Crie um pacote de conteúdo para o Aethrium Hub.\n"
                f"Projetos: {_projects_summary()}\n"
                "[POST DE ABERTURA] Boas-vindas e novidades. "
                "[DESTAQUE DA SEMANA] Um projeto em destaque. "
                "[DICA DA SEMANA] Uma dica de gameplay. "
                "[TEASER] Feature em desenvolvimento. "
                "[CALL-TO-ACTION] Chamada de engajamento."
            ),
        ),
        "amanda_infra_check": lambda: _run_agent_job(
            slug="amanda",
            title=f"Auditoria de infraestrutura (manual) — {now.strftime('%d/%m/%Y %H:%M')} UTC",
            prompt=(
                f"Auditoria imediata da infraestrutura Aethrium Hub.\n"
                f"Projetos no Studio: {_projects_summary()}\n"
                "[INFRAESTRUTURA] Status de todos os serviços. "
                "[PLANEJAMENTO] Requisitos de infra para os projetos. "
                "[ALERTAS] Riscos identificados. "
                "Se tudo ok: [INFRAESTRUTURA OK]. Se crítico: comece com [URGENTE]."
            ),
        ),
    }
    if key not in jobs:
        return {"error": f"Job '{key}' not found. Available: {list(jobs.keys())}"}
    asyncio.create_task(jobs[key]())
    return {"status": "triggered", "job": key}


async def _job_carlos_backlog_sweep_force():
    """Force-run the backlog sweep ignoring the time window guard."""
    from db import prisma

    pending = await prisma.task.find_many(
        where={"status": "PENDING", "isChat": False},
        order=[{"priority": "desc"}, {"createdAt": "asc"}],
        take=1,
        include={"owner": True, "project": True},
    )

    if not pending:
        print("[SCHEDULER] Backlog sweep (manual): no PENDING tasks")
        return

    task = pending[0]
    project_slug = task.project.slug if task.project else None
    project_name = task.project.displayName if task.project else "Aethrium Hub"

    context = {
        "summary": task.description or task.title,
        "task_id": task.id,
        "scheduled": True,
        "autonomous": True,
    }
    if project_slug:
        context["project_slug"] = project_slug

    await _run_agent_job(
        slug="carlos",
        title=f"[AUTO] {task.title}",
        prompt=(
            f"Tarefa autônoma recebida do backlog:\n\n"
            f"**Título:** {task.title}\n"
            f"**Projeto:** {project_name}\n"
            f"**Descrição:** {task.description or '(sem descrição adicional)'}\n\n"
            f"Analise esta tarefa, execute ou delegue ao especialista correto via [PIPELINE: agente1, agente2]."
        ),
        context=context,
    )

    await prisma.task.update(
        where={"id": task.id},
        data={"status": "RUNNING"},
    )



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
