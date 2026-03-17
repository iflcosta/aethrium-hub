import os
import google.generativeai as genai
from dotenv import load_dotenv

# Force load backend/.env
env_path = os.path.join(os.path.dirname(__file__), ".env")
load_dotenv(env_path)

def list_models():
    api_key = os.getenv("GOOGLE_API_KEY")
    if not api_key:
        print("API KEY NOT FOUND")
        return

    genai.configure(api_key=api_key)
    
    print("Listing available models from Google AI API...")
    try:
        for m in genai.list_models():
            if 'generateContent' in m.supported_generation_methods:
                print(f"Name: {m.name}, Display: {m.display_name}")
    except Exception as e:
        print(f"ERROR listing models: {e}")

if __name__ == "__main__":
    list_models()
