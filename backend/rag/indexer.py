import asyncio
from rag.chunker import stream_project_chunks
from rag.pinecone_client import PineconeClient
from db import prisma

async def index_project(project_slug: str, project_path: str) -> dict:
    """
    Indexa o projeto em streaming: nunca carrega mais de BATCH_SIZE chunks
    na memória ao mesmo tempo, evitando OOM no Render 512MB.
    """
    try:
        client = PineconeClient()
        print(f"[INDEXER] Starting walk: {project_slug} at {project_path}")

        BATCH_SIZE = 25
        batch = []
        total = 0
        batch_num = 0

        for chunk in stream_project_chunks(project_path, project_slug):
            batch.append(chunk)

            if len(batch) >= BATCH_SIZE:
                batch_num += 1
                try:
                    await asyncio.to_thread(client.upsert_chunks, batch)
                    for c in batch:
                        try:
                            await prisma.knowledgechunk.upsert(
                                where={"pineconeVecId": c["id"]},
                                data={
                                    "create": {
                                        "source": c["metadata"]["source"],
                                        "chunkIndex": c["metadata"]["chunk_index"],
                                        "content": c["text"][:500],
                                        "pineconeVecId": c["id"],
                                        "metadata": c["metadata"],
                                    },
                                    "update": {
                                        "content": c["text"][:500],
                                        "metadata": c["metadata"],
                                    }
                                }
                            )
                        except Exception as e:
                            print(f"[INDEXER] Prisma error chunk {c['id']}: {e}")
                    total += len(batch)
                    print(f"[INDEXER] Batch {batch_num} done — {total} chunks indexed")
                except Exception as e:
                    print(f"[INDEXER] ERROR batch {batch_num}: {e}")
                    raise
                finally:
                    batch = []  # libera memória

        # flush do último batch parcial
        if batch:
            batch_num += 1
            await asyncio.to_thread(client.upsert_chunks, batch)
            for c in batch:
                try:
                    await prisma.knowledgechunk.upsert(
                        where={"pineconeVecId": c["id"]},
                        data={
                            "create": {
                                "source": c["metadata"]["source"],
                                "chunkIndex": c["metadata"]["chunk_index"],
                                "content": c["text"][:500],
                                "pineconeVecId": c["id"],
                                "metadata": c["metadata"],
                            },
                            "update": {
                                "content": c["text"][:500],
                                "metadata": c["metadata"],
                            }
                        }
                    )
                except Exception as e:
                    print(f"[INDEXER] Prisma error chunk {c['id']}: {e}")
            total += len(batch)

        print(f"[INDEXER] SUCCESS: Indexed {total} chunks for {project_slug}")
        return {"status": "completed", "chunks_total": total, "project": project_slug}

    except Exception as e:
        import traceback
        print(f"[INDEXER] FATAL ERROR: {e}")
        traceback.print_exc()
        return {"status": "error", "message": str(e)}


async def query_rag(query_text: str, project_slug: str = None,
                    agent_slug: str = None, top_k: int = 5) -> list[dict]:
    client = PineconeClient()
    filter_dict = {}
    if project_slug:
        filter_dict["project"] = {"$eq": project_slug}
    if agent_slug:
        filter_dict["agent"] = {"$eq": agent_slug}
    # Run in thread — sentence-transformers encode is CPU-bound
    return await asyncio.to_thread(
        client.query,
        query_text,
        top_k,
        filter_dict if filter_dict else None
    )
