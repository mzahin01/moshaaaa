import requests
import json
import time

url = "https://mzahin01-moshaaaa.hf.space/gradio_api/call/analyze"
file_path = "test.jpg"

def run_test(payload_data):
    try:
        response = requests.post(url, json={"data": payload_data})
        if response.status_code != 200:
            print(f"POST Error {response.status_code}: {response.text}")
            return
        
        event_id = response.json().get("event_id")
        print(f"Event ID: {event_id}")
        
        sse_url = f"{url}/{event_id}"
        print(f"Streaming from {sse_url}")
        
        with requests.get(sse_url, stream=True) as r:
            for line in r.iter_lines():
                if line:
                    decoded_line = line.decode('utf-8')
                    print(decoded_line)
                    if "event: complete" in decoded_line or "event: error" in decoded_line:
                        break
    except Exception as e:
        print(f"Error: {e}")

variants = [
    [{"path": file_path}],
    [{"path": file_path, "meta": {"_type": "gradio.FileData"}}],
    [{"path": file_path, "meta": {"_type": "gradio.FileData"}, "orig_name": "test.jpg", "mime_type": "image/jpeg"}]
]

for i, variant in enumerate(variants, 1):
    print(f"\n--- Testing Variant {i} ---")
    print(f"Payload Data: {json.dumps(variant)}")
    run_test(variant)
