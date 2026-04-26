#!/bin/bash

# Configuration
API_BASE="https://rifath1729-mosquito-breeding-spot-detection.hf.space/gradio_api" # Assuming local for now, if not provided. Adjust if needed.
# Since the prompt doesn't specify the API host, I'll check if a server is running or use a placeholder.
# Usually these tasks expect a local server or a specific URL. I will check for 7860 first.

URLS=(
  "https://images.unsplash.com/photo-1528825871115-3581a5387919?auto=format&fit=crop&w=900&q=80"
  "https://images.unsplash.com/photo-1534088568595-a066f410bcda?auto=format&fit=crop&w=900&q=80"
  "https://raw.githubusercontent.com/gradio-app/gradio/main/test/test_files/bus.png"
)

for i in "${!URLS[@]}"; do
  URL="${URLS[$i]}"
  FILE="/tmp/mosq_case_$i.jpg"
  echo "--- Case $i: $URL ---"
  
  # 1) Download
  curl -s -L "$URL" -o "$FILE"
  
  # 2) Upload
  UPLOAD_RES=$(curl -s -X POST "$API_BASE/upload" -F "files=@$FILE")
  echo "Upload Response: $UPLOAD_RES"
  
  # Extract filename from upload response (Gradio format is typically a list of strings or objects)
  # Trying to extract the path accurately.
  FILE_PATH=$(echo "$UPLOAD_RES" | grep -oE '"[^"]+"' | head -n 1 | tr -d '"')
  
  if [ -z "$FILE_PATH" ]; then
    echo "Failed to get file path from upload"
    continue
  fi

  # 3) Trigger
  # Using data format for /call/analyze. Usually Gradio 4+ uses {"data": [arg1, arg2, ...]}
  TRIGGER_RES=$(curl -s -X POST "$API_BASE/call/analyze" \
    -H "Content-Type: application/json" \
    -d "{\"data\": [{\"path\": \"$FILE_PATH\"}]}")
  echo "Trigger Response: $TRIGGER_RES"
  
  EVENT_ID=$(echo "$TRIGGER_RES" | grep -oE '"event_id": *"[^"]+"' | cut -d'"' -f4)
  
  if [ -z "$EVENT_ID" ]; then
    echo "Failed to get event_id"
    continue
  fi

  # 4) Fetch
  echo "Full SSE body:"
  curl -s "$API_BASE/call/analyze/$EVENT_ID"
  echo -e "\n"
done
