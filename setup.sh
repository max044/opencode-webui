#!/bin/bash

# OpenCode setup for Railway (Persistent Global Server Init)

echo "--- 🛠️ Initializing Persistent Server ---"

# 1. Fix permissions (Cloud volumes are often mounted as root)
# When running as root in start.sh, we can fix these permissions directly.
chown -R opencode:opencode /home/opencode

# 2. Ensure essential directories exist
mkdir -p /home/opencode/workspace
mkdir -p /home/opencode/mongodb-data
chown -R opencode:opencode /home/opencode/workspace /home/opencode/mongodb-data

# 3. Handle data directory for OpenCode
export OPENCODE_DATA_DIR=${OPENCODE_DATA_DIR:-/home/opencode/.opencode}
mkdir -p "$OPENCODE_DATA_DIR"
chown -R opencode:opencode "$OPENCODE_DATA_DIR"

# 4. Start MongoDB in background
echo "🍃 Starting MongoDB..."
# Clean up potential stale lock files
rm -f /home/opencode/mongodb-data/mongod.lock

# Try to start mongod as opencode user.
# Using --fork requires the logpath to be writable.
touch /home/opencode/mongodb.log
chown opencode:opencode /home/opencode/mongodb.log

# Start MongoDB as opencode user
runuser -u opencode -- mongod --dbpath /home/opencode/mongodb-data --logpath /home/opencode/mongodb.log --bind_ip 127.0.0.1 --fork --logappend || {
    echo "⚠️ MongoDB failed to start with --fork. Checking logs..."
    tail -n 20 /home/opencode/mongodb.log
}

# 5. Git configuration
if [ ! -z "$GIT_USER_NAME" ]; then
    git config --global user.name "$GIT_USER_NAME"
fi
if [ ! -z "$GIT_USER_EMAIL" ]; then
    git config --global user.email "$GIT_USER_EMAIL"
fi

# 6. Repository cloning
cd /home/opencode/workspace

if [ ! -z "$GITHUB_REPO_URL" ]; then
    REPO_URL=$GITHUB_REPO_URL
    REPO_NAME=$(basename "$REPO_URL" .git)

    if [ ! -z "$GITHUB_TOKEN" ]; then
        echo "🔑 GitHub Token found. Preparing clone..."
        CLEAN_URL=$(echo $REPO_URL | sed 's/https:\/\///')
        REPO_URL="https://${GITHUB_TOKEN}@${CLEAN_URL}"
    fi

    if [ -d "$REPO_NAME/.git" ]; then
        echo "✅ Repository '$REPO_NAME' already exists. Skipping clone."
    else
        if [ -d "$REPO_NAME" ]; then
            rm -rf "$REPO_NAME"
        fi
        git clone "$REPO_URL"
        echo "✅ Successfully cloned '$REPO_NAME'."
    fi
fi

echo "--- 🚀 Server Initialization Complete ---"
