from rag.chunker import chunk_project
from rag.pinecone_client import PineconeClient
from db import prisma

async def index_project(project_slug: str,
                        project_path: str) -> dict:
    try:
        client = PineconeClient()
        print(f"[INDEXER] Starting walk: {project_slug} at {project_path}")
        chunks = chunk_project(project_path, project_slug)
        print(f"[INDEXER] Extracted {len(chunks)} chunks from {project_path}")

        if not chunks:
            print(f"[INDEXER] WARNING: No indexable chunks found in {project_path}")
            return {"status": "error", "message": "No files found"}

        batch_size = 50
        print(f"[INDEXER] Beginning Pinecone upsert in batches of {batch_size}")
        for i in range(0, len(chunks), batch_size):
            batch = chunks[i:i + batch_size]
            try:
                client.upsert_chunks(batch)
                print(f"[INDEXER] Batch {i//batch_size + 1} synced to Pinecone")
            except Exception as e:
                print(f"[INDEXER] ERROR in Pinecone batch {i//batch_size + 1}: {e}")
                raise

        print(f"[INDEXER] Storing metadata in Prisma...")
        for chunk in chunks:
            try:
                await prisma.knowledgechunk.upsert(
                    where={"pineconeVecId": chunk["id"]},
                    data={
                        "create": {
                            "source": chunk["metadata"]["source"],
                            "chunkIndex": chunk["metadata"]["chunk_index"],
                            "content": chunk["text"][:500],
                            "pineconeVecId": chunk["id"],
                            "metadata": chunk["metadata"],
                        },
                        "update": {
                            "content": chunk["text"][:500],
                            "metadata": chunk["metadata"],
                        }
                    }
                )
            except Exception as e:
                print(f"[INDEXER] ERROR saving chunk {chunk['id']} to Prisma: {e}")

        print(f"[INDEXER] SUCCESS: Indexed {len(chunks)} chunks for {project_slug}")
        return {
            "status": "completed",
            "chunks_total": len(chunks),
            "project": project_slug
        }
    except Exception as e:
        import traceback
        print(f"[INDEXER] FATAL ERROR during indexing: {e}")
        traceback.print_exc()
        return {"status": "error", "message": str(e)}

async def query_rag(query_text: str,
                    project_slug: str = None,
                    agent_slug: str = None,
                    top_k: int = 5) -> list[dict]:
    client = PineconeClient()
    filter_dict = {}
    if project_slug:
        filter_dict["project"] = {"$eq": project_slug}
    if agent_slug:
        filter_dict["agent"] = {"$eq": agent_slug}
    return client.query(
        query_text, top_k=top_k,
        filter=filter_dict if filter_dict else None
    )
