import os
import base64
from pathlib import Path
from groq import Groq

VISION_MODEL = "llama-3.2-11b-vision-preview"

MAP_PROMPT = """
Analise este mapa de OTServ e descreva:
1. Layout geral da área (cidade, dungeon, campo, etc.)
2. Estruturas visíveis (casas, templos, spawns)
3. Pontos de interesse identificados
4. Sugestões de melhoria ou expansão
5. Coordenadas aproximadas de áreas importantes
Responda em português.
"""

MAP_PROMPT_DETAIL = """
Analise este mapa de OTServ e descreva em detalhes:
1. Tipo de área (cidade, dungeon, campo aberto, etc.)
2. Estruturas e elementos visíveis
3. Densidade de tiles e organização espacial
4. Sugestões técnicas para o mapper (RME)
5. AIDs sugeridos para teleports e áreas especiais
Responda em português.
"""


def _groq_vision(image_base64: str, prompt: str) -> str:
    client = Groq(api_key=os.getenv("GROQ_API_KEY"))
    response = client.chat.completions.create(
        model=VISION_MODEL,
        messages=[{
            "role": "user",
            "content": [
                {"type": "text", "text": prompt},
                {"type": "image_url", "image_url": {"url": f"data:image/png;base64,{image_base64}"}},
            ],
        }],
        max_tokens=1024,
    )
    return response.choices[0].message.content


async def analyze_map_image(image_path: str, question: str = None) -> dict:
    """Analyze a map image using Groq Vision. Used by Beatriz."""
    try:
        image_data = Path(image_path).read_bytes()
        image_base64 = base64.b64encode(image_data).decode()
        analysis = _groq_vision(image_base64, question or MAP_PROMPT)
        return {"status": "success", "analysis": analysis, "image_path": image_path}
    except Exception as e:
        return {"status": "error", "message": str(e)}


async def analyze_map_from_base64(image_base64: str, question: str = None) -> dict:
    """Analyze map from base64 encoded image using Groq Vision."""
    try:
        analysis = _groq_vision(image_base64, question or MAP_PROMPT_DETAIL)
        return {"status": "success", "analysis": analysis}
    except Exception as e:
        return {"status": "error", "message": str(e)}
