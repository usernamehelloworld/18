#!/bin/bash

# Variables - Ensure these match the Modelfile and Notebook expectations
BASE_MODEL_TAG="artifish/llama3.2-uncensored"
CUSTOM_MODEL_TAG="artifish/llama3.2-uncensored-8k" # Tag to create
MODELFILE_NAME="IncreaseContext.Modelfile" # Modelfile to use for create

echo "--- Starting Ollama Setup Script ---"
echo "Base model: ${BASE_MODEL_TAG}"
echo "Custom tag to create: ${CUSTOM_MODEL_TAG}"
echo "Using Modelfile: ${MODELFILE_NAME}"

# 1. Install/Update Ollama
echo "[1/5] Installing/Updating Ollama..."
curl -fsSL https://ollama.ai/install.sh | sh
INSTALL_STATUS=$?
if [ ${INSTALL_STATUS} -ne 0 ]; then
    echo "ERROR: Ollama installation failed."
    exit 1
fi

# 2. Start Ollama server in the background
echo "[2/5] Starting Ollama server in the background..."
# Start in background, redirect output to avoid cluttering terminal
ollama serve > /tmp/ollama_server.log 2>&1 &
SERVER_PID=$!

# 3. Wait for server to initialize
echo "[3/5] Waiting 15 seconds for server to start (PID: ${SERVER_PID})..."
sleep 15

# Check if server process is still running using its PID
if ! kill -0 ${SERVER_PID} > /dev/null 2>&1; then
    echo "ERROR: Ollama server failed to start or exited prematurely."
    echo "Check logs: cat /tmp/ollama_server.log"
    # Attempt to start it in foreground to see error directly (might block script)
    # echo "Attempting to start server in foreground..."
    # ollama serve
    exit 1
fi
echo "Ollama server process appears to be running (PID: ${SERVER_PID})."

# 4. Pull the base model (if not already present)
echo "[4/5] Pulling base model ${BASE_MODEL_TAG}..."
ollama pull ${BASE_MODEL_TAG}
PULL_STATUS=$?
if [ ${PULL_STATUS} -ne 0 ]; then
    echo "WARNING: 'ollama pull ${BASE_MODEL_TAG}' failed with status ${PULL_STATUS}. Proceeding anyway."
    # Don't exit, maybe model exists or create can use cache
fi

# 5. Create the custom model using the Modelfile
echo "[5/5] Creating custom model ${CUSTOM_MODEL_TAG} from ${MODELFILE_NAME}..."
sleep 2 # Short delay before creating
if [ -f "${MODELFILE_NAME}" ]; then
  ollama create ${CUSTOM_MODEL_TAG} -f ${MODELFILE_NAME}
  CREATE_STATUS=$?
  if [ ${CREATE_STATUS} -ne 0 ]; then
    echo "ERROR: 'ollama create ${CUSTOM_MODEL_TAG}' failed with status ${CREATE_STATUS}. Check Modelfile syntax."
    # Don't exit, server is still running, user might use other models
  else
    echo "Custom model tag '${CUSTOM_MODEL_TAG}' created successfully."
    # Verify the created model's parameters
    echo "Verifying parameters for ${CUSTOM_MODEL_TAG}:"
    ollama show --modelfile ${CUSTOM_MODEL_TAG} | grep "PARAMETER num_"
  fi
else
  echo "ERROR: Modelfile ${MODELFILE_NAME} not found in current directory."
  # Don't exit, server is still running
fi

echo ""
echo "--- Ollama Setup Complete ---"
echo "Ollama server should be running in the background (PID: ${SERVER_PID})."
echo "**Leave this terminal window open!**"
echo ""
echo "You can now pull other models if needed (e.g., 'ollama pull llama3')."
echo "Then use the Gradio interface launched from the Colab notebook."
echo ""

# Keep the script running in the background to potentially keep the session alive
# Or simply rely on the user keeping the xterm open.
# sleep infinity # Uncomment if you want the script itself to block
