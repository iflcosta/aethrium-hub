import os
import google.generativeai as genai
from dotenv import load_dotenv

# Force load backend/.env
env_path = os.path.join(os.path.dirname(__file__), ".env")
load_dotenv(env_path)

def test_google_direct():
    api_key = os.getenv("GOOGLE_API_KEY")
    print(f"Testing Google AI SDK directly...")
    print(f"API KEY present: {bool(api_key)}")
    if not api_key: return

    genai.configure(api_key=api_key)
    
    model_id = "models/gemini-2.5-flash"
    print(f"Using model: {model_id}")
    
    try:
        model = genai.GenerativeModel(model_id)
        response = model.generate_content("Olá, pode se apresentar?")
        print(f"Response received!")
        print(f"Text: {response.text}")
    except Exception as e:
        print(f"ERROR: {e}")

if __name__ == "__main__":
    test_google_direct()
