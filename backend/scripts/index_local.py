"""
Indexação local do projeto para o Pinecone.
Roda no seu PC, não precisa do Render.

Uso:
    cd backend
    pip install fastembed pinecone python-dotenv
    python scripts/index_local.py
"""
import os
import sys
from pathlib import Path
from dotenv import load_dotenv

load_dotenv(Path(__file__).parent.parent / ".env")

PINECONE_API_KEY = os.getenv("PINECONE_API_KEY")
PINECONE_HOST = os.getenv("PINECONE_HOST")
PINECONE_INDEX = os.getenv("PINECONE_INDEX", "aethrium-studio")
PROJECT_SLUG = "baiak-thunder-86"
PROJECT_PATH = Path(__file__).parent.parent / "projects" / PROJECT_SLUG

SUPPORTED_EXTENSIONS = [".lua", ".cpp", ".h", ".xml", ".md", ".txt", ".json"]
MAX_CHUNK_SIZE = 1500
OVERLAP = 100
BATCH_SIZE = 50


def stream_chunks(project_path: Path, project_slug: str):
    for file_path in project_path.rglob("*"):
        if not file_path.is_file():
            continue
        if file_path.suffix not in SUPPORTED_EXTENSIONS:
            continue
        try:
            content = file_path.read_text(encoding="utf-8", errors="ignore")
        except Exception:
            continue
        if not content.strip():
            continue

        relative = str(file_path).replace("\\", "/")
        chunk_type = {
            ".lua": "lua_script", ".cpp": "cpp_source", ".h": "cpp_header",
            ".xml": "xml_config", ".md": "documentation",
        }.get(file_path.suffix, "text")
        agent = {"lua_script": "rafael", "cpp_source": "viktor", "cpp_header": "viktor",
                 "xml_config": "rafael", "documentation": "carlos"}.get(chunk_type, "carlos")

        start, idx = 0, 0
        while start < len(content):
            end = min(start + MAX_CHUNK_SIZE, len(content))
            text = f"File: {relative}\n\n{content[start:end]}"
            yield {
                "id": f"{project_slug}:{relative}:{idx}",
                "text": text,
                "metadata": {"source": relative, "project": project_slug,
                             "agent": agent, "type": chunk_type, "chunk_index": idx}
            }
            start = end - OVERLAP
            if end >= len(content):
                break
            idx += 1


def main():
    if not PINECONE_API_KEY:
        print("ERRO: PINECONE_API_KEY não encontrada no .env")
        sys.exit(1)
    if not PROJECT_PATH.exists():
        print(f"ERRO: Pasta não encontrada: {PROJECT_PATH}")
        sys.exit(1)

    print(f"Carregando modelo sentence-transformers...")
    from sentence_transformers import SentenceTransformer
    model = SentenceTransformer("sentence-transformers/all-MiniLM-L6-v2")
    print("Modelo carregado.")

    from pinecone import Pinecone
    pc = Pinecone(api_key=PINECONE_API_KEY)
    index = pc.Index(host=PINECONE_HOST) if PINECONE_HOST else pc.Index(PINECONE_INDEX)
    print(f"Conectado ao Pinecone: {PINECONE_HOST or PINECONE_INDEX}")

    batch, total, batch_num = [], 0, 0

    for chunk in stream_chunks(PROJECT_PATH, PROJECT_SLUG):
        batch.append(chunk)
        if len(batch) >= BATCH_SIZE:
            batch_num += 1
            texts = [c["text"] for c in batch]
            embeddings = model.encode(texts, normalize_embeddings=True, batch_size=32)
            vectors = [(c["id"], emb.tolist(), {**c["metadata"], "text": c["text"][:500]})
                       for c, emb in zip(batch, embeddings)]
            index.upsert(vectors=vectors)
            total += len(batch)
            print(f"Batch {batch_num}: {total} chunks indexados")
            batch = []

    if batch:
        texts = [c["text"] for c in batch]
        embeddings = model.encode(texts, normalize_embeddings=True, batch_size=32)
        vectors = [(c["id"], emb.tolist(), {**c["metadata"], "text": c["text"][:500]})
                   for c, emb in zip(batch, embeddings)]
        index.upsert(vectors=vectors)
        total += len(batch)
        print(f"Batch final: {total} chunks indexados")

    print(f"\nSUCESSO! {total} chunks indexados no Pinecone.")


if __name__ == "__main__":
    main()
