#!/bin/bash

# OpenCode Automation Wrapper for Railway
set -e

echo "--- 🚀 Launching OpenCode Automation ---"

# 1. Run the setup script to prepare the environment and workspace
if [ -f "./setup.sh" ]; then
    bash ./setup.sh
else
    echo "Warning: setup.sh not found, skipping initial configuration."
fi

# 2. Start the OpenCode server
echo "--- 💻 Starting OpenCode Web Interface on port ${PORT:-4096} ---"
exec opencode web --port "${PORT:-4096}" --hostname "0.0.0.0"
