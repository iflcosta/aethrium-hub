from pinecone import Pinecone
import os

INDEX_DIM = 384  # all-MiniLM-L6-v2 output dimensions

_model = None


def _get_model():
    global _model
    if _model is None:
        from fastembed import TextEmbedding
        _model = TextEmbedding("sentence-transformers/all-MiniLM-L6-v2")
    return _model


def _embed_one(text: str) -> list[float]:
    return [float(x) for x in list(_get_model().embed([text]))[0]]


def _embed_batch(texts: list[str]) -> list[list[float]]:
    return [[float(x) for x in v] for v in _get_model().embed(texts)]


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
        embeddings = _embed_batch(texts)
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
            vec = _embed_one(text)
            results = self.index.query(
                vector=vec,
                top_k=top_k,
                filter=filter,
                include_metadata=True,
            )
            matches = results.matches if hasattr(results, "matches") else results.get("matches", [])
            return [
                {
                    "id": m.id if hasattr(m, "id") else m["id"],
                    "score": m.score if hasattr(m, "score") else m["score"],
                    "text": (m.metadata if hasattr(m, "metadata") else m.get("metadata", {})).get("text", ""),
                    "source": (m.metadata if hasattr(m, "metadata") else m.get("metadata", {})).get("source", ""),
                    "project": (m.metadata if hasattr(m, "metadata") else m.get("metadata", {})).get("project", ""),
                }
                for m in matches
            ]
        except Exception as e:
            print(f"[PINECONE] Query error: {e}")
            return []

    def delete_project(self, project_slug: str):
        self.index.delete(filter={"project": {"$eq": project_slug}})

    def _embed_query(self, text: str) -> list[float]:
        return _embed_one(text)
