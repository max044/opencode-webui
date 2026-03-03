#!/bin/bash

# OpenCode Automation Wrapper for Railway

echo "--- 🚀 Launching OpenCode Automation ---"

# 1. Run the setup script to prepare the environment and workspace
if [ -f "/usr/local/bin/setup.sh" ]; then
    bash /usr/local/bin/setup.sh
else
    echo "Warning: setup.sh not found at /usr/local/bin/setup.sh, skipping initial configuration."
fi

# 2. Start the OpenCode server
echo "--- 💻 Starting OpenCode Web Interface on port ${PORT:-4096} ---"

# Debug: Confirm authentication variables are set
if [ ! -z "$OPENCODE_SERVER_PASSWORD" ]; then
    echo "🔐 OPENCODE_SERVER_PASSWORD is set (${#OPENCODE_SERVER_PASSWORD} chars)"
else
    echo "⚠️ OPENCODE_SERVER_PASSWORD is NOT set — login will fail!"
fi
echo "👤 Username: ${OPENCODE_SERVER_USERNAME:-opencode}"

# Ensure opencode is in PATH or use absolute path
OPCODE_BIN=$(command -v opencode || echo "/opt/opencode/bin/opencode")

if [ ! -f "$OPCODE_BIN" ]; then
    # Fallback to older paths just in case
    if [ -f "/home/opencode/.local/bin/opencode" ]; then
        OPCODE_BIN="/home/opencode/.local/bin/opencode"
    fi
fi

exec "$OPCODE_BIN" web --port "${PORT:-4096}" --hostname "0.0.0.0"
