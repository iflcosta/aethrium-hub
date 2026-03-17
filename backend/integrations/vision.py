import google.generativeai as genai
import os
import base64
from pathlib import Path

genai.configure(api_key=os.getenv("GOOGLE_API_KEY"))

async def analyze_map_image(image_path: str, question: str = None) -> dict:
    """
    Analyze a map image using Gemini Vision
    Used by Beatriz to understand map layouts
    """
    try:
        model = genai.GenerativeModel("gemini-3.1-flash-lite-preview")

        # Load image
        image_data = Path(image_path).read_bytes()
        image_part = {
            "mime_type": "image/png",
            "data": base64.b64encode(image_data).decode()
        }

        prompt = question or """
        Analise este mapa de OTServ e descreva:
        1. Layout geral da área (cidade, dungeon, campo, etc.)
        2. Estruturas visíveis (casas, templos, spawns)
        3. Pontos de interesse identificados
        4. Sugestões de melhoria ou expansão
        5. Coordenadas aproximadas de áreas importantes
        Responda em português.
        """

        response = model.generate_content([prompt, image_part])
        return {
            "status": "success",
            "analysis": response.text,
            "image_path": image_path
        }
    except Exception as e:
        return {"status": "error", "message": str(e)}

async def analyze_map_from_base64(image_base64: str, question: str = None) -> dict:
    """Analyze map from base64 encoded image"""
    try:
        model = genai.GenerativeModel("gemini-3.1-flash-lite-preview")

        image_part = {
            "mime_type": "image/png",
            "data": image_base64
        }

        prompt = question or """
        Analise este mapa de OTServ e descreva em detalhes:
        1. Tipo de área (cidade, dungeon, campo aberto, etc.)
        2. Estruturas e elementos visíveis
        3. Densidade de tiles e organização espacial
        4. Sugestões técnicas para o mapper (RME)
        5. AIDs sugeridos para teleports e áreas especiais
        Responda em português.
        """

        response = model.generate_content([prompt, image_part])
        return {"status": "success", "analysis": response.text}
    except Exception as e:
        return {"status": "error", "message": str(e)}
