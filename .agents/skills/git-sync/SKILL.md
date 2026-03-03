---
name: git-sync
description: Automates Git pull, commit, and push operations for a seamless "auto-save" experience.
---

# Git Sync Skill

This skill allows the AI to automatically synchronize the workspace with a
remote Git repository. This is especially useful in web-based environments where
manual Git operations might be cumbersome.

## Workflow

### 1. Initial Pull (Startup)

When the environment starts, the AI should ensure the latest code is pulled from
the remote repository.

### 2. Auto-Commit and Push (During/After Work)

After making significant changes or when requested by the user, the AI should:

1. Check for local changes.
2. Stage all changes.
3. Commit with a descriptive message (or an automated "OpenCode Auto-sync"
   message).
4. Push to the remote repository.

## Commands

The skill uses the `sync.sh` script located in the `scripts/` directory of this
skill.

### Sync Workspace

```bash
bash .agents/skills/git-sync/scripts/sync.sh
```

## Environment Variables Required

- `GITHUB_TOKEN`: A Personal Access Token with repo scope.
- `GITHUB_REPO_URL`: The full URL of the repository (including the token if not
  using a credential helper). Example:
  `https://<TOKEN>@github.com/user/repo.git`

## Best Practices

- **Atomic Commits**: Try to commit logical chunks of work.
- **Conflict Handling**: The `sync.sh` script attempts to handle simple rebase
  situations, but if a complex conflict occurs, the AI should notify the user.
- **Security**: Never log the `GITHUB_TOKEN` or `GITHUB_REPO_URL` containing the
  token to the terminal or logs.
