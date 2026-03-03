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

# Prioritize the binary path in /opt (not shadowed by volumes)
OPCODE_BIN="/opt/opencode/bin/opencode"

if [ ! -f "$OPCODE_BIN" ]; then
    echo "⚠️ Binary not found at $OPCODE_BIN, hunting for alternative..."
    OPCODE_BIN=$(command -v opencode || echo "/home/opencode/.local/bin/opencode")
fi

echo "📍 Using binary: $OPCODE_BIN"

if [ ! -f "$OPCODE_BIN" ]; then
    echo "❌ FATAL: OpenCode binary not found!"
    exit 1
fi

exec "$OPCODE_BIN" web --port "${PORT:-4096}" --hostname "0.0.0.0"
