import httpx
from urllib.parse import quote


POLLINATIONS_BASE = "https://image.pollinations.ai/prompt"


async def generate_image_url(prompt: str, width: int = 1024, height: int = 1024) -> dict:
    """
    Generates an image URL via Pollinations.ai (free, no API key required).
    Returns the URL directly — the image is rendered on first access.
    """
    try:
        encoded = quote(prompt)
        url = f"{POLLINATIONS_BASE}/{encoded}?width={width}&height={height}&nologo=true"
        return {"status": "success", "url": url, "prompt": prompt}
    except Exception as e:
        return {"status": "error", "message": str(e)}


async def generate_map_concept(area_description: str) -> dict:
    """
    Generate concept art for a map area. Used by Beatriz.
    Style: top-down RPG, Tibia-inspired pixel art.
    """
    prompt = (
        f"top-down RPG map concept art, Tibia OTServ style, {area_description}, "
        "medieval fantasy, pixel art, detailed tiles, dark atmosphere"
    )
    return await generate_image_url(prompt, width=1024, height=1024)


async def generate_social_banner(content_description: str) -> dict:
    """
    Generate a social media banner for Discord / forums. Used by Lucas and Mariana.
    """
    prompt = (
        f"game promotional banner, medieval MMORPG, Tibia inspired, {content_description}, "
        "epic fantasy art, dramatic lighting, dark background, high quality digital art"
    )
    return await generate_image_url(prompt, width=1200, height=628)


async def generate_guide_image(guide_topic: str) -> dict:
    """
    Generate an illustrative image for a player guide. Used by Mariana.
    """
    prompt = (
        f"RPG tutorial illustration, Tibia MMORPG style, {guide_topic}, "
        "clean UI, friendly art style, medieval fantasy"
    )
    return await generate_image_url(prompt, width=800, height=600)
