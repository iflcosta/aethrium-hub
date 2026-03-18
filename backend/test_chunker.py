from rag.chunker import chunk_project
import os

project_path = "C:/Users/Iago Lopes/.gemini/antigravity/scratch/aethrium-hub/projects/baiak-thunder-86"
project_slug = "baiak-thunder-86"

print(f"Testing chunk_project for: {project_path}")
try:
    chunks = chunk_project(project_path, project_slug)
    print(f"Success! Generated {len(chunks)} chunks.")
    for i, c in enumerate(chunks[:3]):
        print(f"Chunk {i}: {c['metadata']['source']}")
except Exception as e:
    print(f"Error: {e}")
