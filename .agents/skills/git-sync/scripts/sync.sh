#!/bin/bash

# Git Sync Script for OpenCode
# Automates: pull --rebase, add, commit, push

set -e

echo "Starting Git sync..."

# 1. Check if git is initialized
if [ ! -d ".git" ]; then
    echo "Error: Not a git repository."
    exit 1
fi

# 2. Configure Git if not already set
if [ -z "$(git config user.name)" ]; then
    git config user.name "OpenCode AI"
    git config user.email "ai@opencode.ai"
fi

# 3. Pull latest changes with rebase to avoid merge commits
echo "Pulling latest changes..."
git pull --rebase origin main || git pull --rebase origin master || echo "Pull failed, proceeding with local changes (check for conflicts later)."

# 4. Check for changes
if [ -z "$(git status --porcelain)" ]; then
    echo "No changes to sync."
    exit 0
fi

# 5. Stage and Commit
echo "Committing changes..."
git add .
COMMIT_MSG="OpenCode Auto-sync: $(date '+%Y-%m-%d %H:%M:%S')"
git commit -m "$COMMIT_MSG"

# 6. Push
echo "Pushing to remote..."
git push origin HEAD || echo "Push failed. You might need to resolve conflicts manually."

echo "Git sync complete!"
