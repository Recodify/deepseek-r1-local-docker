#!/bin/bash

echo "Starting Ollama service..."
ollama serve &

# Wait for Ollama to start (more robust check)
echo "Waiting for Ollama server to initialize..."
max_attempts=30
attempt=0
while ! curl -s http://localhost:${OLLAMA_PORT:-11434}/api/tags >/dev/null; do
    sleep 1
    attempt=$((attempt + 1))
    if [ $attempt -eq $max_attempts ]; then
        echo "Timeout waiting for Ollama to start"
        exit 1
    fi
done

MODEL="deepseek-r1:${MODEL_SIZE}"

# More robust model check and pull
if ! ollama list | grep -q "$MODEL"; then
    echo "Model not found, pulling $MODEL..."
    max_retries=3
    retry=0
    while [ $retry -lt $max_retries ]; do
        if ollama pull "$MODEL"; then
            echo "Successfully pulled $MODEL"
            break
        else
            retry=$((retry + 1))
            echo "Failed to pull model (attempt $retry of $max_retries)"
            sleep 5
        fi
    done
    if [ $retry -eq $max_retries ]; then
        echo "Failed to pull model after $max_retries attempts"
        exit 1
    fi
else
    echo "Model $MODEL already exists in volume, skipping pull"
fi

# Add clear ready message
echo "
========================================
Done
   - Model loaded: '$MODEL' ✓
   - Server status: running ✓
        - Port ${OLLAMA_PORT:-11434}
   - WebUI url: http://localhost:${WEBUI_PORT:-8080}
🚀 Ollama is ready!
========================================
"

# Keep container running
tail -f /dev/null
