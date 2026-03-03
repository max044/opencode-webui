#!/bin/bash

# OpenCode setup for Railway (Full Automation)

echo "Preparing workspace..."
mkdir -p /home/opencode/workspace

# Fix ownership (Railway volumes are mounted as root)
sudo chown -R opencode:opencode /home/opencode/workspace

cd /home/opencode/workspace

# 1. Configurer Git
if [ ! -z "$GIT_USER_NAME" ]; then
    git config --global user.name "$GIT_USER_NAME"
fi
if [ ! -z "$GIT_USER_EMAIL" ]; then
    git config --global user.email "$GIT_USER_EMAIL"
fi

# 2. Clone repository automatically
if [ ! -z "$GITHUB_REPO_URL" ]; then
    REPO_URL=$GITHUB_REPO_URL
    REPO_NAME=$(basename "$REPO_URL" .git)

    # Inject token into URL if provided
    if [ ! -z "$GITHUB_TOKEN" ]; then
        echo "🔑 GitHub Token found. Cloning securely..."
        CLEAN_URL=$(echo $REPO_URL | sed 's/https:\/\///')
        REPO_URL="https://${GITHUB_TOKEN}@${CLEAN_URL}"
    else
        echo "⚠️ No GITHUB_TOKEN found. Pushing back to GitHub might require manual authentication."
    fi

    # Only clone if the repo directory doesn't exist yet
    if [ -d "$REPO_NAME/.git" ]; then
        echo "✅ Repository '$REPO_NAME' already exists. Skipping clone."
    else
        # Clean up incomplete clone if directory exists without .git
        if [ -d "$REPO_NAME" ]; then
            echo "🧹 Cleaning up incomplete clone of '$REPO_NAME'..."
            rm -rf "$REPO_NAME"
        fi
        git clone "$REPO_URL"
        echo "✅ Successfully cloned '$REPO_NAME'."
    fi
else
    echo "ℹ️ No GITHUB_REPO_URL provided. Workspace initialized as empty."
fi

echo "Setup complete!"
