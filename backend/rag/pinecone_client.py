from pinecone import Pinecone
import requests
import os

EMBED_MODEL = "models/text-embedding-004"
GOOGLE_EMBED_URL = f"https://generativelanguage.googleapis.com/v1/{EMBED_MODEL}"
INDEX_DIM = 1024  # Pinecone index was created with 1024 dimensions


def _google_embed_batch(texts: list[str], task_type: str = "RETRIEVAL_DOCUMENT") -> list[list[float]]:
    """Call Google's batchEmbedContents v1 API directly."""
    api_key = os.getenv("GOOGLE_API_KEY")
    payload = {
        "requests": [
            {
                "model": EMBED_MODEL,
                "content": {"parts": [{"text": t[:1500]}]},
                "taskType": task_type,
            }
            for t in texts
        ]
    }
    resp = requests.post(
        f"{GOOGLE_EMBED_URL}:batchEmbedContents",
        json=payload,
        params={"key": api_key},
        timeout=60,
    )
    resp.raise_for_status()
    return [e["values"] for e in resp.json()["embeddings"]]


def _google_embed_one(text: str, task_type: str = "RETRIEVAL_QUERY") -> list[float]:
    """Embed a single text by reusing the batch endpoint with one item."""
    return _google_embed_batch([text], task_type=task_type)[0]


def _pad(vector: list[float]) -> list[float]:
    """Pad or truncate to INDEX_DIM (1024)."""
    if len(vector) < INDEX_DIM:
        return vector + [0.0] * (INDEX_DIM - len(vector))
    return vector[:INDEX_DIM]


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
                _pad(embeddings[i]),
                {**c.get("metadata", {}), "text": c["text"][:500]},
            )
            for i, c in enumerate(chunks)
        ]
        self.index.upsert(vectors=vectors)

    def query(self, text: str, top_k: int = 5, filter: dict = None) -> list[dict]:
        try:
            vec = _pad(_google_embed_one(text))
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

    # Expose for diagnostic endpoint
    def _embed_query(self, text: str) -> list[float]:
        return _google_embed_one(text, task_type="RETRIEVAL_QUERY")
