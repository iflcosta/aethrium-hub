import requests
import json
import time

def test_run():
    url = "http://localhost:8000/agents/carlos/run"
    payload = {
        "task_id": "test-" + str(int(time.time())),
        "prompt": "Olá, pode se apresentar?",
        "context": {}
    }
    
    print(f"Testing POST {url}...")
    try:
        response = requests.post(url, json=payload)
        print(f"Status: {response.status_code}")
        print(f"Response: {json.dumps(response.json(), indent=2)}")
        
        if response.status_code == 200:
            exec_id = response.json().get("execution_id")
            if exec_id:
                print(f"Successfully created execution: {exec_id}")
            else:
                print("Error: execution_id not found in response")
        else:
            print(f"Error: Received status {response.status_code}")
            
    except Exception as e:
        print(f"Connection failed: {e}")

if __name__ == "__main__":
    test_run()
