from pinecone import Pinecone
import requests
import os
import time

EMBED_MODEL = "models/gemini-embedding-001"
GOOGLE_EMBED_URL = f"https://generativelanguage.googleapis.com/v1beta/{EMBED_MODEL}"
INDEX_DIM = 1024


def _google_embed_one(text: str, task_type: str = "RETRIEVAL_QUERY") -> list[float]:
    """Call Google's embedContent API for a single text."""
    api_key = os.getenv("GOOGLE_API_KEY")
    payload = {
        "model": EMBED_MODEL,
        "content": {"parts": [{"text": text[:8000]}]},
        "taskType": task_type,
        "outputDimensionality": INDEX_DIM,
    }
    resp = requests.post(
        f"{GOOGLE_EMBED_URL}:embedContent",
        json=payload,
        params={"key": api_key},
        timeout=30,
    )
    resp.raise_for_status()
    return resp.json()["embedding"]["values"]


def _google_embed_batch(texts: list[str], task_type: str = "RETRIEVAL_DOCUMENT") -> list[list[float]]:
    """Embed multiple texts sequentially, pausing every 10 to respect rate limits."""
    embeddings = []
    for i, text in enumerate(texts):
        embeddings.append(_google_embed_one(text, task_type))
        if (i + 1) % 10 == 0:
            time.sleep(1)
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
            vec = _google_embed_one(text)
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
        return _google_embed_one(text, task_type="RETRIEVAL_QUERY")
