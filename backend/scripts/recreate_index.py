"""
Run this once locally to recreate the Pinecone index with 384 dimensions.
Usage: cd backend && python scripts/recreate_index.py
"""
import os
import time
from pinecone import Pinecone, ServerlessSpec
from dotenv import load_dotenv

load_dotenv(os.path.join(os.path.dirname(__file__), "../.env"))

pc = Pinecone(api_key=os.getenv("PINECONE_API_KEY"))
index_name = "aethrium-studio"

existing = [i.name for i in pc.list_indexes()]
if index_name in existing:
    print(f"Deleting existing index: {index_name}")
    pc.delete_index(index_name)
    time.sleep(5)
    print("Deleted.")

print(f"Creating index: {index_name} with 384 dimensions (cosine)")
pc.create_index(
    name=index_name,
    dimension=384,
    metric="cosine",
    spec=ServerlessSpec(cloud="aws", region="us-east-1")
)
print("Done. Index ready for sentence-transformers/all-MiniLM-L6-v2")
