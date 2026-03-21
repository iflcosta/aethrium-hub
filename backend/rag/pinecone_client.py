from pinecone import Pinecone
import os

INDEX_DIM = 384  # all-MiniLM-L6-v2 output dimensions

_model = None


def _get_model():
    global _model
    if _model is None:
        from sentence_transformers import SentenceTransformer
        _model = SentenceTransformer("sentence-transformers/all-MiniLM-L6-v2")
    return _model


def _embed_one(text: str) -> list[float]:
    return _get_model().encode(text, normalize_embeddings=True).tolist()


def _embed_batch(texts: list[str]) -> list[list[float]]:
    return _get_model().encode(texts, normalize_embeddings=True, batch_size=32).tolist()


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
        return _embed_one(text)
