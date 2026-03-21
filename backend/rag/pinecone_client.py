from pinecone import Pinecone
import google.generativeai as genai
import os


class PineconeClient:
    def __init__(self):
        self.pc = Pinecone(api_key=os.getenv("PINECONE_API_KEY"))
        host = os.getenv("PINECONE_HOST")
        if host:
            self.index = self.pc.Index(host=host)
        else:
            index_name = os.getenv("PINECONE_INDEX", "aethrium-studio")
            self.index = self.pc.Index(index_name)

        genai.configure(api_key=os.getenv("GOOGLE_API_KEY"))
        self._embed_model = "models/text-embedding-004"

    def _embed_texts(self, texts: list[str]) -> list[list[float]]:
        """Embed a list of texts using Google's embedding API directly."""
        result = genai.embed_content(
            model=self._embed_model,
            content=texts,
            task_type="retrieval_document",
        )
        # Returns {"embedding": [vec1, vec2, ...]} for lists
        embeddings = result.get("embedding", [])
        # If single text was passed, wrap it
        if embeddings and not isinstance(embeddings[0], list):
            embeddings = [embeddings]
        return embeddings

    def _embed_query(self, text: str) -> list[float]:
        """Embed a single query string."""
        result = genai.embed_content(
            model=self._embed_model,
            content=text,
            task_type="retrieval_query",
        )
        return result.get("embedding", [])

    def _pad(self, vector: list[float], target: int = 768) -> list[float]:
        """Pad or truncate vector to target dimension."""
        if len(vector) < target:
            return vector + [0.0] * (target - len(vector))
        return vector[:target]

    def upsert_chunks(self, chunks: list[dict]):
        texts = [chunk["text"] for chunk in chunks]
        embeddings = self._embed_texts(texts)

        vectors = []
        for i, chunk in enumerate(chunks):
            vec = self._pad(embeddings[i])
            metadata = {**chunk.get("metadata", {}), "text": chunk["text"][:500]}
            vectors.append((chunk["id"], vec, metadata))

        self.index.upsert(vectors=vectors)

    def query(self, text: str, top_k: int = 5, filter: dict = None) -> list[dict]:
        query_vec = self._pad(self._embed_query(text))
        try:
            results = self.index.query(
                vector=query_vec,
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
