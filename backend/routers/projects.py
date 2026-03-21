from fastapi import APIRouter, BackgroundTasks, Query
from rag.indexer import index_project, query_rag
from pydantic import BaseModel
from db import prisma

router = APIRouter(prefix="/projects", tags=["Projects"])

@router.get("/embedding-test")
async def embedding_test():
    """Standalone test: call Google embedding API directly and return result."""
    import os, requests as _req
    api_key = os.getenv("GOOGLE_API_KEY")
    result = {"api_key_prefix": api_key[:8] + "..." if api_key else "NOT SET"}
    models = ["models/text-embedding-004", "models/embedding-001"]
    for m in models:
        for version in ["v1beta", "v1"]:
            url = f"https://generativelanguage.googleapis.com/{version}/{m}:batchEmbedContents"
            try:
                r = _req.post(url, json={"requests": [{"model": m, "content": {"parts": [{"text": "hello world"}]}, "taskType": "RETRIEVAL_QUERY"}]}, params={"key": api_key}, timeout=10)
                result[f"{m}@{version}"] = {"status": r.status_code, "body": r.text[:300]}
            except Exception as ex:
                result[f"{m}@{version}"] = {"error": str(ex)}
    return result

class IndexProjectRequest(BaseModel):
    project_slug: str
    project_path: str

class QueryRequest(BaseModel):
    query: str
    project_slug: str = None
    agent_slug: str = None
    top_k: int = 5

@router.post("/index")
async def start_indexing(
    req: IndexProjectRequest,
    background_tasks: BackgroundTasks
):
    background_tasks.add_task(
        index_project, req.project_slug, req.project_path
    )
    return {
        "status": "indexing_started",
        "project": req.project_slug
    }

@router.get("/index/{project_slug}/status")
async def get_status(project_slug: str):
    # Using raw SQL for robust JSON filtering in Postgres
    query = 'SELECT COUNT(*) as count FROM "KnowledgeChunk" WHERE metadata->>\'project\' = $1'
    result = await prisma.query_raw(query, project_slug)
    count = result[0]['count'] if result else 0
    return {
        "project": project_slug,
        "chunks_indexed": count
    }

@router.post("/query")
async def query_project(req: QueryRequest):
    results = await query_rag(
        req.query, req.project_slug,
        req.agent_slug, req.top_k
    )
    return {"results": results, "count": len(results)}

@router.get("/index/{project_slug}/diagnose")
async def diagnose_indexing(project_slug: str):
    """Step-by-step diagnostic: path, embeddings, pinecone, db."""
    import os
    from pathlib import Path
    from rag.chunker import chunk_project
    from rag.pinecone_client import PineconeClient

    result = {}
    project_path = f"/app/projects/{project_slug}"

    # 1. Path check
    p = Path(project_path)
    result["path_exists"] = p.exists()
    if p.exists():
        files = list(p.rglob("*"))
        result["total_files"] = len(files)
        result["sample_files"] = [str(f) for f in files[:5]]
    else:
        result["error"] = f"Path not found: {project_path}"
        return result

    # 2. Chunking
    try:
        chunks = chunk_project(project_path, project_slug)
        result["chunks_extracted"] = len(chunks)
        result["sample_chunk_id"] = chunks[0]["id"] if chunks else None
    except Exception as e:
        result["chunking_error"] = str(e)
        return result

    if not chunks:
        result["error"] = "No chunks extracted — no supported files found"
        return result

    # 3. Embeddings test — probe multiple models to find what works
    import requests as _req
    api_key = os.getenv("GOOGLE_API_KEY")
    probe_models = [
        "models/text-embedding-004",
        "models/embedding-001",
        "models/text-multilingual-embedding-002",
    ]
    probe_results = {}
    working_model = None
    first_error_body = None
    result["api_key_prefix"] = api_key[:8] + "..." if api_key else "NOT SET"
    for m in probe_models:
        for version in ["v1beta", "v1"]:
            url = f"https://generativelanguage.googleapis.com/{version}/{m}:batchEmbedContents"
            try:
                r = _req.post(url, json={"requests": [{"model": m, "content": {"parts": [{"text": "test"}]}, "taskType": "RETRIEVAL_QUERY"}]}, params={"key": api_key}, timeout=10)
                probe_results[f"{m}@{version}"] = r.status_code
                if r.status_code == 200 and working_model is None:
                    working_model = (m, version)
                elif first_error_body is None:
                    first_error_body = r.text[:500]
            except Exception as ex:
                probe_results[f"{m}@{version}"] = str(ex)
    result["embedding_probe"] = probe_results
    result["first_error_body"] = first_error_body
    if working_model is None:
        result["embedding_error"] = "No embedding model returned 200 — see embedding_probe for details"
        return result
    result["working_model"] = f"{working_model[0]}@{working_model[1]}"
    try:
        pc = PineconeClient()
        vec = pc._embed_query(chunks[0]["text"][:200])
        result["embedding_dim"] = len(vec)
        result["embedding_ok"] = True
    except Exception as e:
        result["embedding_error"] = str(e)
        return result

    # 4. Pinecone test upsert (1 chunk)
    try:
        pc.upsert_chunks([chunks[0]])
        result["pinecone_upsert_ok"] = True
    except Exception as e:
        result["pinecone_error"] = str(e)
        return result

    # 5. DB test write
    try:
        c = chunks[0]
        await prisma.knowledgechunk.upsert(
            where={"pineconeVecId": c["id"] + ":diag"},
            data={
                "create": {
                    "source": c["metadata"]["source"],
                    "chunkIndex": c["metadata"]["chunk_index"],
                    "content": c["text"][:100],
                    "pineconeVecId": c["id"] + ":diag",
                    "metadata": c["metadata"],
                },
                "update": {"content": c["text"][:100]}
            }
        )
        result["db_write_ok"] = True
    except Exception as e:
        result["db_error"] = str(e)

    return result

@router.delete("/{project_slug}/index")
async def delete_index(project_slug: str):
    from rag.pinecone_client import PineconeClient
    PineconeClient().delete_project(project_slug)
    
    # Raw SQL for deletion to avoid JSON filter issues
    delete_query = 'DELETE FROM "KnowledgeChunk" WHERE metadata->>\'project\' = $1'
    await prisma.execute_raw(delete_query, project_slug)
    
    return {"status": "deleted", "project": project_slug}
