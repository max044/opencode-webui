#!/bin/bash

# OpenCode Automation Wrapper for Railway
set -e

echo "--- 🚀 Launching OpenCode Automation ---"

# 1. Run the setup script to prepare the environment and workspace
if [ -f "/usr/local/bin/setup.sh" ]; then
    bash /usr/local/bin/setup.sh
else
    echo "Warning: setup.sh not found at /usr/local/bin/setup.sh, skipping initial configuration."
fi

# 2. Start the OpenCode server
echo "--- 💻 Starting OpenCode Web Interface on port ${PORT:-4096} ---"

# Ensure opencode is in PATH or use absolute path
OPCODE_BIN=$(command -v opencode || echo "/home/opencode/.local/bin/opencode")

if [ ! -f "$OPCODE_BIN" ]; then
    # Checking another common path just in case
    if [ -f "/home/opencode/.opencode/bin/opencode" ]; then
        OPCODE_BIN="/home/opencode/.opencode/bin/opencode"
    fi
fi

exec "$OPCODE_BIN" web --port "${PORT:-4096}" --hostname "0.0.0.0"
