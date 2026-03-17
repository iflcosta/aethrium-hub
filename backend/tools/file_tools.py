import os

def read_file(file_path: str) -> str:
    """Read a .lua or .cpp file from the project"""
    if not os.path.exists(file_path):
        return f"Error: File not found at {file_path}"
    
    with open(file_path, "r", encoding="utf-8") as f:
        return f.read()

def write_file(file_path: str, content: str) -> str:
    """Write content to a .lua or .cpp file"""
    # Create directories if they don't exist
    os.makedirs(os.path.dirname(file_path), exist_ok=True)
    
    with open(file_path, "w", encoding="utf-8") as f:
        f.write(content)
        
    return f"Successfully wrote to {file_path}"
