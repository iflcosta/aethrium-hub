import asyncio
import os
import sys
from dotenv import load_dotenv

load_dotenv()

# Add backend directory to sys.path so we can import PineconeClient
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from rag.pinecone_client import PineconeClient

STUDIO_ARCHITECTURE_MD = """
# Arquitetura do Aethrium Hub (Aethrium Studio)

O Aethrium Hub é a plataforma central que orquestra a Aethrium Studio.
Ele consiste em:
1. **Frontend**: Next.js (App Router), TailwindCSS, Zustand (State), e uma UI inspirada em cyberpunk/industrial (preto, verde neon, cinza).
2. **Backend**: FastAPI (Python), Prisma (ORM), PostgreSQL.
3. **Agentes Inteligentes**: Construídos usando vLLM / Groq, orquestrados pelo `base_agent.py`. Cada agente tem um `slug` único e um prefixo de cargo (ex: [CTO] Carlos, [LUA] Rafael).
4. **Vetorização/RAG**: Pinecone. O cliente está em `rag/pinecone_client.py`. Usamos embeddings para armazenar conhecimento técnico de cada projeto.
5. **Comunicação Discord**: Em `integrations/discord.py`, os agentes usam um Bot Token (`DISCORD_TOKEN`) para enviar mensagens dinâmicas aos canais (usando a tag `[DISCORD: id_do_canal]`).
6. **Deploy**: O backend roda no Render como um Web Service via Dockerfile. O DB é hospedado no Supabase.

A arquitetura do Aethrium Hub permite que múltiplos agentes atuem em série ou em paralelo. Quando um agente quer passar código para testes, ele usa a tag `[HANDOFF: sophia]`.
"""

async def index_studio_knowledge():
    print("[INDEX_STUDIO] Iniciando indexação do conhecimento mestre...")
    client = PineconeClient()
    
    # We use a special project slug 'aethrium-studio' for global studio knowledge
    chunks_to_index = [{
        "id": "studio:arch:overview:1",
        "text": STUDIO_ARCHITECTURE_MD,
        "metadata": {
            "source": "scripts/index_studio.py",
            "project": "aethrium-studio",
            "agent": "system",
            "type": "architecture_overview",
            "chunk_index": 0,
        },
    }]
    
    await asyncio.to_thread(client.upsert_chunks, chunks_to_index)
    print(f"[INDEX_STUDIO] Conhecimento da Aethrium Studio indexado com sucesso no Pinecone.")

if __name__ == "__main__":
    asyncio.run(index_studio_knowledge())
