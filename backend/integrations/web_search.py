import asyncio
from typing import List, Dict


async def search_web(query: str, max_results: int = 5) -> List[Dict]:
    """
    Search the web using DuckDuckGo. Free, no API key required.
    Returns list of {title, body, href} dicts.
    Runs the sync DDGS client in a thread to avoid blocking the event loop.
    """
    try:
        from duckduckgo_search import DDGS

        def _sync_search():
            with DDGS() as ddgs:
                return list(ddgs.text(query, max_results=max_results))

        results = await asyncio.to_thread(_sync_search)
        return results or []
    except ImportError:
        print("[WEB_SEARCH] duckduckgo-search not installed. Run: pip install duckduckgo-search")
        return []
    except Exception as e:
        print(f"[WEB_SEARCH] Error for query '{query}': {e}")
        return []


async def search_otserv_topics(prompt: str) -> str:
    """
    Run targeted OTServ market searches based on the prompt.
    Used by Leonardo before the LLM call so findings enrich the response.
    Returns a formatted block ready for injection into the system prompt.
    """
    # Build 2 focused queries from the prompt
    base = prompt[:120].replace("\n", " ").strip()
    queries = [
        f"OTServ Open Tibia server {base}",
        f"Tibia MMORPG private server {base} 2024",
    ]

    all_results: List[Dict] = []
    for q in queries:
        results = await search_web(q, max_results=4)
        all_results.extend(results)

    if not all_results:
        return ""

    # Deduplicate by URL
    seen_urls = set()
    unique = []
    for r in all_results:
        url = r.get("href", "")
        if url not in seen_urls:
            seen_urls.add(url)
            unique.append(r)

    formatted = "\n\n--- RESULTADOS DE PESQUISA WEB (DuckDuckGo — tempo real) ---\n"
    for r in unique[:6]:
        title = r.get("title", "Sem título")
        body = r.get("body", "")[:250]
        href = r.get("href", "")
        formatted += f"\n**{title}**\n{body}\nFonte: {href}\n"

    return formatted
