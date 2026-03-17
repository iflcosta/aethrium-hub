import asyncio
import os
import json
from dotenv import load_dotenv
from langchain_google_genai import ChatGoogleGenerativeAI
from langchain_core.messages import SystemMessage, HumanMessage

# Force load backend/.env
env_path = os.path.join(os.path.dirname(__file__), ".env")
load_dotenv(env_path)

async def test_llm():
    api_key = os.getenv("GOOGLE_API_KEY")
    print(f"Testing Gemini LLM...")
    print(f"API KEY present: {bool(api_key)}")
    if api_key:
        print(f"API KEY prefix: {api_key[:8]}...")

    model = "models/gemini-flash-latest"
    print(f"Using model: {model}")
    
    llm = ChatGoogleGenerativeAI(
        model=model,
        temperature=0.7,
        google_api_key=api_key
    )
    
    messages = [
        SystemMessage(content="Você é um assistente prestativo."),
        HumanMessage(content="Olá, pode se apresentar?")
    ]
    
    print("Sending request to Gemini...")
    try:
        # Try a simple invoke first (non-streaming for debugging)
        response = await llm.ainvoke(messages)
        print(f"Response received successfully!")
        print(f"Content: {response.content}")
        print(f"Length: {len(response.content)} chars")
    except Exception as e:
        print(f"ERROR calling Gemini: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    asyncio.run(test_llm())
