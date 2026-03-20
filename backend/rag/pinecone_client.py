from pinecone import Pinecone
import os
from langchain_google_genai import GoogleGenerativeAIEmbeddings

class PineconeClient:
    def __init__(self):
        self.pc = Pinecone(api_key=os.getenv("PINECONE_API_KEY"))
        self.index_name = os.getenv("PINECONE_INDEX", "aethrium-studio")
        host = os.getenv("PINECONE_HOST")
        if host:
            self.index = self.pc.Index(host=host)
        else:
            self.index = self.pc.Index(self.index_name)
        self.embeddings = GoogleGenerativeAIEmbeddings(
            model="models/text-embedding-004",
            google_api_key=os.getenv("GOOGLE_API_KEY")
        )

    def upsert_chunks(self, chunks: list[dict]):
        # Batch collect texts for embedding
        texts = [chunk["text"] for chunk in chunks]
        embeds = self.embeddings.embed_documents(texts)
        
        vectors = []
        for i, chunk in enumerate(chunks):
            vector = embeds[i]
            # Handle dimension mismatch (Google 004 is 768, index is 1024)
            if len(vector) < 1024:
                vector = vector + [0.0] * (1024 - len(vector))
            elif len(vector) > 1024:
                vector = vector[:1024]
                
            vectors.append((
                chunk["id"],
                vector,
                {**chunk.get("metadata", {}), "text": chunk["text"][:500]}
            ))
            
        self.index.upsert(vectors=vectors)

    def query(self, text: str, top_k: int = 5,
              filter: dict = None) -> list[dict]:
        # Generate query vector
        query_vector = self.embeddings.embed_query(text)
        if len(query_vector) < 1024:
            query_vector = query_vector + [0.0] * (1024 - len(query_vector))
        elif len(query_vector) > 1024:
            query_vector = query_vector[:1024]

        try:
            results = self.index.query(
                vector=query_vector,
                top_k=top_k,
                filter=filter,
                include_metadata=True
            )
            return [
                {
                    "id": match["id"],
                    "score": match["score"],
                    "text": match["metadata"].get("text", ""),
                    "source": match["metadata"].get("source", ""),
                    "project": match["metadata"].get("project", ""),
                }
                for match in results.get("matches", [])
            ]
        except Exception as e:
            print(f"[PINECONE] Query Error: {e}")
            return []

    def delete_project(self, project_slug: str):
        self.index.delete(
            filter={"project": {"$eq": project_slug}}
        )
