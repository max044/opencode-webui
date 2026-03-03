#!/bin/bash

# OpenCode setup for Railway (Persistent Global Server Init)

echo "--- 🛠️ Initializing Persistent Server ---"

# 1. Self-Correction: Bootstrap /home/opencode if empty (on new volumes)
# This is crucial for mounting volumes over the home directory without
# losing the pre-installed tools (Bun, UV, Rust, OpenCode CLI)
if [ ! -d "/home/opencode/.local" ]; then
    echo "⬇️ New volume detected. Bootstrapping home directory from template..."
    cp -rp /usr/local/share/opencode-template/. /home/opencode/
    echo "✅ Home directory bootstrapped."
fi

# 2. Fix permissions (Just in case volume mounting messed them up)
sudo chown -R opencode:opencode /home/opencode

# 3. Handle data directory for OpenCode
# Default to /home/opencode/.opencode if not set to ensure persistence
export OPENCODE_DATA_DIR=${OPENCODE_DATA_DIR:-/home/opencode/.opencode}
mkdir -p "$OPENCODE_DATA_DIR"

# 4. Start MongoDB
echo "🍃 Starting MongoDB in the background..."
# Railway volumes can cause permission issues on standard mongodb-org.conf paths
# Launching with specific user-writable paths
mongod --dbpath /home/opencode/mongodb-data --logpath /home/opencode/mongodb.log --fork || {
    # If standard mongod fails, check if we need to create the dbpath
    mkdir -p /home/opencode/mongodb-data
    mongod --dbpath /home/opencode/mongodb-data --logpath /home/opencode/mongodb.log --bind_ip 127.0.0.1 --fork
}

# 5. Git Automation
if [ ! -z "$GIT_USER_NAME" ]; then
    git config --global user.name "$GIT_USER_NAME"
fi
if [ ! -z "$GIT_USER_EMAIL" ]; then
    git config --global user.email "$GIT_USER_EMAIL"
fi

# 6. Repository cloning (In workspace subdirectory)
# Re-using the logic from previous fix to support multiple repos
cd /home/opencode/workspace 2>/dev/null || { mkdir -p /home/opencode/workspace && cd /home/opencode/workspace; }

if [ ! -z "$GITHUB_REPO_URL" ]; then
    REPO_URL=$GITHUB_REPO_URL
    REPO_NAME=$(basename "$REPO_URL" .git)

    # Inject token into URL if provided
    if [ ! -z "$GITHUB_TOKEN" ]; then
        echo "🔑 GitHub Token found. Preparing clone..."
        CLEAN_URL=$(echo $REPO_URL | sed 's/https:\/\///')
        REPO_URL="https://${GITHUB_TOKEN}@${CLEAN_URL}"
    fi

    # Only clone if the repo directory doesn't exist yet
    if [ -d "$REPO_NAME/.git" ]; then
        echo "✅ Repository '$REPO_NAME' already exists. Skipping clone."
    else
        # Clean up incomplete clone if directory exists without .git
        if [ -d "$REPO_NAME" ]; then
            rm -rf "$REPO_NAME"
        fi
        git clone "$REPO_URL"
        echo "✅ Successfully cloned '$REPO_NAME'."
    fi
fi

echo "--- 🚀 Server Initialization Complete ---"
