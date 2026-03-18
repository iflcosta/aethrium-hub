from fastapi import APIRouter, BackgroundTasks, Query
from rag.indexer import index_project, query_rag
from pydantic import BaseModel
from db import prisma

router = APIRouter(prefix="/projects", tags=["Projects"])

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

@router.delete("/{project_slug}/index")
async def delete_index(project_slug: str):
    from rag.pinecone_client import PineconeClient
    PineconeClient().delete_project(project_slug)
    
    # Raw SQL for deletion to avoid JSON filter issues
    delete_query = 'DELETE FROM "KnowledgeChunk" WHERE metadata->>\'project\' = $1'
    await prisma.execute_raw(delete_query, project_slug)
    
    return {"status": "deleted", "project": project_slug}
