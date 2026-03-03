#!/bin/bash

# OpenCode setup for Railway (Full Automation)
set -e

# 1. Workspace initialization
echo "Preparing workspace..."
mkdir -p /home/opencode/workspace
cd /home/opencode/workspace

# 2. Configurer Git (Non-sensible)
if [ ! -z "$GIT_USER_NAME" ]; then
    git config --global user.name "$GIT_USER_NAME"
fi
if [ ! -z "$GIT_USER_EMAIL" ]; then
    git config --global user.email "$GIT_USER_EMAIL"
fi

# 3. Clone repository automatically
if [ ! -d ".git" ] && [ ! -z "$GITHUB_REPO_URL" ]; then
    echo "First run detected. Cloning repository..."
    
    # Inject token into URL if provided
    REPO_URL=$GITHUB_REPO_URL
    if [ ! -z "$GITHUB_TOKEN" ]; then
        # Remove https:// from repo URL to inject token
        CLEAN_URL=$(echo $REPO_URL | sed 's/https:\/\///')
        REPO_URL="https://${GITHUB_TOKEN}@${CLEAN_URL}"
    fi
    
    git clone "$REPO_URL" .
    echo "Successfully cloned repository."
fi

echo "Setup complete!"

