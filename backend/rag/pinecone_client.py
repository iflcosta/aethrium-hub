from pinecone import Pinecone
import requests
import os
import time

EMBED_MODEL = "models/gemini-embedding-001"
GOOGLE_EMBED_URL = f"https://generativelanguage.googleapis.com/v1beta/{EMBED_MODEL}"
INDEX_DIM = 1024


def _google_embed_one(text: str, task_type: str = "RETRIEVAL_QUERY", retries: int = 6) -> list[float]:
    """Call Google's embedContent API. retries=0 means fail fast on 429 (for live queries)."""
    api_key = os.getenv("GOOGLE_API_KEY")
    payload = {
        "model": EMBED_MODEL,
        "content": {"parts": [{"text": text[:8000]}]},
        "taskType": task_type,
        "outputDimensionality": INDEX_DIM,
    }
    for attempt in range(max(retries, 1)):
        resp = requests.post(
            f"{GOOGLE_EMBED_URL}:embedContent",
            json=payload,
            params={"key": api_key},
            timeout=30,
        )
        if resp.status_code == 429:
            if attempt >= retries - 1:
                raise RuntimeError(f"[EMBED] Rate limited (429) — daily quota likely exhausted")
            wait = 2 ** attempt
            print(f"[EMBED] Rate limited, retrying in {wait}s...")
            time.sleep(wait)
            continue
        resp.raise_for_status()
        return resp.json()["embedding"]["values"]
    raise RuntimeError(f"[EMBED] Embedding failed after {retries} retries")


def _google_embed_batch(texts: list[str], task_type: str = "RETRIEVAL_DOCUMENT") -> list[list[float]]:
    """Embed multiple texts sequentially with rate limit respect."""
    embeddings = []
    for i, text in enumerate(texts):
        embeddings.append(_google_embed_one(text, task_type))
        time.sleep(0.5)  # 2 req/s sustained to stay within free tier limits
    return embeddings


class PineconeClient:
    def __init__(self):
        self.pc = Pinecone(api_key=os.getenv("PINECONE_API_KEY"))
        host = os.getenv("PINECONE_HOST")
        if host:
            self.index = self.pc.Index(host=host)
        else:
            self.index = self.pc.Index(os.getenv("PINECONE_INDEX", "aethrium-studio"))

    def upsert_chunks(self, chunks: list[dict]):
        texts = [c["text"] for c in chunks]
        embeddings = _google_embed_batch(texts)

        vectors = [
            (
                c["id"],
                embeddings[i],
                {**c.get("metadata", {}), "text": c["text"][:500]},
            )
            for i, c in enumerate(chunks)
        ]
        self.index.upsert(vectors=vectors)

    def query(self, text: str, top_k: int = 5, filter: dict = None) -> list[dict]:
        try:
            vec = _google_embed_one(text, retries=1)  # fail fast during live queries
            results = self.index.query(
                vector=vec,
                top_k=top_k,
                filter=filter,
                include_metadata=True,
            )
            return [
                {
                    "id": m["id"],
                    "score": m["score"],
                    "text": m["metadata"].get("text", ""),
                    "source": m["metadata"].get("source", ""),
                    "project": m["metadata"].get("project", ""),
                }
                for m in results.get("matches", [])
            ]
        except Exception as e:
            print(f"[PINECONE] Query error: {e}")
            return []

    def delete_project(self, project_slug: str):
        self.index.delete(filter={"project": {"$eq": project_slug}})

    def _embed_query(self, text: str) -> list[float]:
        # retries=1 = fail fast on 429 — don't block live agent requests
        return _google_embed_one(text, task_type="RETRIEVAL_QUERY", retries=1)
