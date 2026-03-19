from datetime import datetime

# Simple in-memory logger for debugging without Render Dashboard
DEBUG_LOGS = []

def log_event(message: str):
    timestamp = datetime.now().isoformat()
    DEBUG_LOGS.append(f"[{timestamp}] {message}")
    if len(DEBUG_LOGS) > 100:
        DEBUG_LOGS.pop(0)
    print(message)
