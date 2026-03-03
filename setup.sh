#!/bin/bash

# OpenCode setup for Railway (Full Automation)
set -e

# 1. Workspace initialization
echo "Preparing workspace..."
mkdir -p /home/opencode/workspace

# Fix ownership (Railway volumes are mounted as root)
sudo chown -R opencode:opencode /home/opencode/workspace

cd /home/opencode/workspace

# 2. Configurer Git (Non-sensible)
if [ ! -z "$GIT_USER_NAME" ]; then
    git config --global user.name "$GIT_USER_NAME"
fi
if [ ! -z "$GIT_USER_EMAIL" ]; then
    git config --global user.email "$GIT_USER_EMAIL"
fi

# 3. Clone repository automatically
if [ ! -d ".git" ]; then
    if [ ! -z "$GITHUB_REPO_URL" ]; then
        echo "⬇️ First run detected: Initializing workspace from $GITHUB_REPO_URL..."

        # Inject token into URL if provided
        REPO_URL=$GITHUB_REPO_URL
        REPO_NAME=$(basename "$REPO_URL" .git)
        if [ ! -z "$GITHUB_TOKEN" ]; then
            echo "🔑 GitHub Token found. Cloning securely..."
            # Remove https:// from repo URL to inject token
            CLEAN_URL=$(echo $REPO_URL | sed 's/https:\/\///')
            REPO_URL="https://${GITHUB_TOKEN}@${CLEAN_URL}"
        else
            echo "⚠️ No GITHUB_TOKEN found. Pushing back to GitHub might require manual authentication."
        fi

        git clone "$REPO_URL"
        echo "✅ Successfully initialized repository."
    else
        echo "ℹ️ No GITHUB_REPO_URL provided. Workspace initialized as empty."
    fi
else
    echo "✅ Git repository already initialized."
fi

echo "Setup complete!"
