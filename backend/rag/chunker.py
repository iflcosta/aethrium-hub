from pathlib import Path

SUPPORTED_EXTENSIONS = [
    ".lua", ".cpp", ".h", ".xml", ".md", ".txt", ".json"
]
MAX_CHUNK_SIZE = 1500
OVERLAP = 100

def chunk_file(file_path: str, project_slug: str) -> list[dict]:
    path = Path(file_path)
    if path.suffix not in SUPPORTED_EXTENSIONS:
        return []
    try:
        content = path.read_text(encoding="utf-8", errors="ignore")
    except Exception:
        return []
    if not content.strip():
        return []

    chunks = []
    start = 0
    chunk_index = 0
    relative_path = str(path).replace("\\", "/")

    while start < len(content):
        end = min(start + MAX_CHUNK_SIZE, len(content))
        chunk_text = content[start:end]

        chunk_type = {
            ".lua": "lua_script",
            ".cpp": "cpp_source",
            ".h": "cpp_header",
            ".xml": "xml_config",
            ".md": "documentation",
        }.get(path.suffix, "text")

        agent_map = {
            "lua_script": "rafael",
            "cpp_source": "viktor",
            "cpp_header": "viktor",
            "xml_config": "rafael",
            "documentation": "carlos",
        }

        chunks.append({
            "id": f"{project_slug}:{relative_path}:{chunk_index}",
            "text": f"File: {relative_path}\n\n{chunk_text}",
            "metadata": {
                "source": relative_path,
                "project": project_slug,
                "agent": agent_map.get(chunk_type, "carlos"),
                "type": chunk_type,
                "chunk_index": chunk_index,
            }
        })

        start = end - OVERLAP
        if end >= len(content):
            break
        chunk_index += 1

    return chunks

def chunk_project(project_path: str,
                  project_slug: str) -> list[dict]:
    all_chunks = []
    project_dir = Path(project_path)

    if not project_dir.exists():
        raise FileNotFoundError(
            f"Project path not found: {project_path}"
        )

    for file_path in project_dir.rglob("*"):
        if file_path.is_file():
            chunks = chunk_file(str(file_path), project_slug)
            all_chunks.extend(chunks)

    return all_chunks
