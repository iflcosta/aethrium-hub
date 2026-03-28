"""
Seed script: populates the Project table with the 7 Aethrium Hub projects
and creates the corresponding project folders with README.md files.

Usage (from /backend):
    python scripts/seed_projects.py
"""

import asyncio
import sys
import os
from pathlib import Path

# Add backend root to path
sys.path.insert(0, str(Path(__file__).parent.parent))

from db import prisma, connect_db, disconnect_db

PROJECTS = [
    {
        "slug": "aethrium-mmorpg",
        "displayName": "Aethrium MMORPG",
        "gameType": "CANARY_MMORPG",
        "division": "STUDIO",
        "engine": "Canary",
        "language": "Lua/C++",
        "isActive": True,
        "metadata": {
            "client": "OTClient",
            "protocol": "custom",
            "status": "em_desenvolvimento",
            "description": "MMORPG customizado com lore e sprites próprios baseado no Tibia"
        },
    },
    {
        "slug": "baiak-thunder-86",
        "displayName": "Baiak Thunder 8.6",
        "gameType": "OTSERV",
        "division": "STUDIO",
        "engine": "TFS 1.5",
        "language": "Lua/C++",
        "isActive": True,
        "metadata": {
            "client": "Tibia 8.60",
            "protocol": "860",
            "status": "em_desenvolvimento",
            "exp_rate": 5,
            "loot_rate": 3,
            "skill_rate": 5,
            "magic_rate": 5,
            "pvp": True
        },
    },
    {
        "slug": "cs2-aethrium",
        "displayName": "CS2 Aethrium",
        "gameType": "CS2",
        "division": "PUBLISHER",
        "engine": "CS2 Dedicated Server",
        "language": "C#",
        "isActive": False,
        "metadata": {
            "status": "aguardando_provisionamento",
            "max_players": 64,
            "tickrate": 128,
            "description": "Servidor Counter-Strike 2 competitivo"
        },
    },
    {
        "slug": "lineage2-aethrium",
        "displayName": "Lineage II Aethrium",
        "gameType": "LINEAGE2",
        "division": "PUBLISHER",
        "engine": "L2J",
        "language": "Java",
        "isActive": False,
        "metadata": {
            "status": "aguardando_provisionamento",
            "chronicle": "Interlude",
            "description": "Servidor Lineage II private server"
        },
    },
    {
        "slug": "mu-online-aethrium",
        "displayName": "MU Online Aethrium",
        "gameType": "MU_ONLINE",
        "division": "PUBLISHER",
        "engine": "MuEmu",
        "language": "C++",
        "isActive": False,
        "metadata": {
            "status": "aguardando_provisionamento",
            "season": 6,
            "description": "Servidor MU Online private server Season 6"
        },
    },
    {
        "slug": "ragnarok-aethrium",
        "displayName": "Ragnarok Aethrium",
        "gameType": "RAGNAROK",
        "division": "PUBLISHER",
        "engine": "rAthena",
        "language": "C/C++",
        "isActive": False,
        "metadata": {
            "status": "aguardando_provisionamento",
            "description": "Servidor Ragnarok Online private server"
        },
    },
    {
        "slug": "haxball-aethrium",
        "displayName": "HaxBall Aethrium",
        "gameType": "HAXBALL",
        "division": "PUBLISHER",
        "engine": "HaxBall Headless",
        "language": "JavaScript",
        "isActive": False,
        "metadata": {
            "status": "aguardando_provisionamento",
            "description": "Servidor HaxBall com modos de jogo customizados"
        },
    },
]

README_TEMPLATE = """# {displayName}

**Division:** {division}
**Game Type:** {gameType}
**Engine:** {engine}
**Language:** {language}
**Status:** {status}

## Description
{description}

## Project Context
This project is managed by the Aethrium Hub AI agent team.
All development, balancing, mapping, and infrastructure tasks are handled by specialized AI agents.

## Agents Assigned
- Carlos (CTO) — architecture and task routing
- Amanda (DevOps) — infrastructure and server management
- Leonardo (Research) — market research and benchmarking
- Lucas (CM) — community and marketing
"""

def create_project_folder(project: dict):
    base_path = Path(__file__).parent.parent / "projects" / project["slug"]
    base_path.mkdir(parents=True, exist_ok=True)

    readme_path = base_path / "README.md"
    if not readme_path.exists():
        metadata = project.get("metadata", {})
        content = README_TEMPLATE.format(
            displayName=project["displayName"],
            division=project["division"],
            gameType=project["gameType"],
            engine=project["engine"],
            language=project["language"],
            status=metadata.get("status", "unknown"),
            description=metadata.get("description", project["displayName"]),
        )
        readme_path.write_text(content)
        print(f"  Created: {readme_path}")
    else:
        print(f"  Exists:  {readme_path}")


async def seed():
    await connect_db()
    print("Connected to database.\n")

    for project in PROJECTS:
        slug = project["slug"]
        existing = await prisma.project.find_unique(where={"slug": slug})
        if existing:
            print(f"[SKIP] {slug} — already exists in database")
        else:
            await prisma.project.create(data={
                "slug": project["slug"],
                "displayName": project["displayName"],
                "gameType": project["gameType"],
                "division": project["division"],
                "engine": project["engine"],
                "language": project["language"],
                "isActive": project["isActive"],
                "metadata": project.get("metadata"),
            })
            print(f"[OK]   {slug} — created")

        create_project_folder(project)

    await disconnect_db()
    print("\nSeed complete.")


if __name__ == "__main__":
    asyncio.run(seed())
