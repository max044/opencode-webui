# OpenCode WebUI Workspace

A containerized development environment running OpenCode WebUI with
comprehensive tooling support. This Docker image includes Python, Node.js, Bun,
Go, Rust, and essential development tools, all running under a non-root
`opencode` user with sudo privileges.

## Features

- **OpenCode WebUI** (v1.1.25) - AI-powered code editor
- **MongoDB 7.0 (Pre-installed & Running)** - Persistent database
- **Lightweight Architecture**: Based on `python:3.13-slim-bookworm` (Debian)
  for maximum efficiency on Railway.
- **Python 3.13** (Pre-installed)
- **Node.js 24.x (LTS)**
- **Bun 1.3.x**
- **Go 1.23.5**
- **Rust 1.92.x**
- **uv** Python package manager
- **Non-root user** (`opencode`) with passwordless sudo access
- **Full persistent home** at `/home/opencode/`

## Quick Start

### Basic Usage

```bash
# Run the OpenCode WebUI
docker run -p 4096:4096 opencode-webui-workspace:latest

# Access at http://localhost:4096
```

### Interactive Shell

```bash
docker run -it --rm opencode-webui-workspace:latest bash
```

### With Environment Variables

```bash
# Create .env file from template
cp .env.example .env
# Edit .env with your secure password

# Run with environment variables
docker run -p 4096:4096 --env-file .env opencode-webui-workspace:latest
```

## Configuration

### Environment Variables

Create a `.env` file (copy from `.env.example`):

```env
OPENCODE_SERVER_PASSWORD=your-secure-password-here
PORT=4096
GITHUB_REPO_URL=
GITHUB_TOKEN=
OPENCODE_DATA_DIR=/home/opencode/workspace/.opencode
```

- **OPENCODE_SERVER_PASSWORD**: Secure password for the server (required for
  authentication)
- **PORT**: Port to listen on (default: 4096)
- **GITHUB_REPO_URL**: (Optional) URL of the repository to clone on startup
- **GITHUB_TOKEN**: (Optional) Personal access token for private repos and AI
  sync
- **OPENCODE_DATA_DIR**: (Optional) Directory to store session data. Set to a
  path inside your volume (like `/home/opencode/workspace/.opencode`) to persist
  conversations across redeployments.

## Volume Mounting

Mount the workspace directory to persist your projects and data:

```bash
docker run -p 4096:4096 \
  -v $(pwd)/workspace:/home/opencode/workspace \
  opencode-webui-workspace:latest
```

The `workspace` directory will be created on your host machine automatically on
first run. Inside the container, all your work is stored in
`/home/opencode/workspace`.

### Docker Compose Example

Run with:

```bash
docker-compose up -d
```

The `./workspace` directory will be created on your host machine on first run.

## Advanced Usage

### Build Locally

```bash
docker build -t opencode-webui-workspace:latest .
```

### Run with Custom Port

```bash
docker run -p 8080:4096 opencode-webui-workspace:latest
```

Access at `http://localhost:8080`

### Override Command

Run an interactive shell instead of the OpenCode WebUI:

```bash
docker run -it --rm opencode-webui-workspace:latest bash
```

Run Python directly:

```bash
docker run -it --rm opencode-webui-workspace:latest python -c "print('Hello from Python 3.13')"
```

### Development Workflow

```bash
# Mount workspace and run interactive shell
docker run -it --rm \
  -v $(pwd)/workspace:/home/opencode/workspace \
  opencode-webui-workspace:latest bash

# Inside container, all your tools are available:
python --version      # Python 3.13.11
node --version        # v24.13.0
bun --version         # 1.3.6
go version            # go1.23.5
rustc --version       # 1.92.0
uv --version          # 0.9.26
rclone version        # Cloud storage sync
wormhole              # Secure file transfer
```

## User & Permissions

The container runs as the `opencode` user (UID: varies) with:

- Full access to `/home/opencode/workspace`
- Passwordless sudo privileges for system administration
- Shell: `/bin/bash`

This ensures security while allowing necessary system operations.

## File Structure

The container provides a clean workspace at `/home/opencode/workspace/`. You can
create your own directory structure:

```
/home/opencode/workspace/
├── projects/          # Your project files (you create this)
├── data/              # Your data files (you create this)
├── logs/              # Your log files (you create this)
└── opencode.json      # OpenCode configuration (included in image)
```

## Publishing Images

The repository includes a GitHub Actions workflow
(`.github/workflows/publish.yml`) that automatically:

- Publishes to GitHub Container Registry (GHCR)
- Supports multiple platforms (linux/amd64, linux/arm64)
- Tags images with git refs and semver tags

### Automatic Publishing

Images are automatically published on:

- Push to `main` branch (tagged as `latest`)
- Push of version tags (v1.0.0, v2.0.0, etc.)
- Manual workflow dispatch from Actions tab

No additional secrets needed - uses `GITHUB_TOKEN` automatically!

## Requirements

- Docker 20.10+
- 4GB+ available disk space for image
- ~500MB for runtime data

## Beam.cloud Deployment (Guides)

Beam.cloud allows us to deploy the OpenCode WebUI environment and securely
expose common web development ports for live previews (like Vite, React, Python
APIs).

### Prerequisites

1. Create a [Beam.cloud](https://www.beam.cloud/) account.
2. Install the Beam CLI:
   `curl https://raw.githubusercontent.com/slai-labs/get-beam/main/get-beam.sh -sSfL | sh`
3. Authenticate the CLI: `beam login`

### Deployment Steps

This setup uses a `beam.Pod` to keep the environment running continuously and
exposes multiple ports for your projects.

1. **Update `app.py`**: Before deploying, edit the `app.py` file to set your
   GitHub username in the `base_image` URL:
   ```python
   image=beam.Image(
       base_image="ghcr.io/YOUR_GITHUB_USER/opencode-webui:latest"
   )
   ```

2. **Configure Secrets**: In the Beam.cloud dashboard (under Secrets), add the
   following necessary environment variables:
   - `OPENCODE_SERVER_PASSWORD`: Your secure password.
   - `GITHUB_REPO_URL`: (Optional) URL of the code you want the AI to work on.
   - `GITHUB_TOKEN`: Your GitHub token for the "Auto-Save" AI skill.

3. **Deploy the Pod**: Run the following command in the terminal to deploy your
   environment:
   ```bash
   beam deploy app.py
   ```

> [!TIP]
> **Previews**: The `app.py` configuration automatically exposes common
> development ports (`3000`, `5173`, `8000`, `8080`) alongside the main OpenCode
> port (`4096`). When you run `npm run dev` inside OpenCode on port 5173, Beam
> will provide a public URL for that specific port, allowing you to preview your
> frontend live!

---
**That's it!** Once the deployment is finished:

1. Open your Beam.cloud provided URL for port 4096.
2. Log in with the username `opencode` and your password.
3. Your repository will be automatically cloned and ready for the AI to start
   coding!
---

### AI-Powered "Auto-Save"

This workspace includes a **Git Sync Skill**. You don't need to know Git
commands; simply ask the AI to "sync my changes" or "push my work," and it will
handle everything safely.

---

## Support

For issues with:

- **OpenCode**: https://github.com/opencodeinc/opencode
- **This Docker setup**: Check Docker logs with `docker logs <container-id>`

## Tips & Tricks

### Keep container running in background

```bash
docker run -d -p 4096:4096 --name opencode opencode-webui-workspace:latest
```

View logs:

```bash
docker logs -f opencode
```

Stop:

```bash
docker stop opencode
```

### Use with VS Code Dev Containers

Install the "Dev Containers" extension and configure
`.devcontainer/devcontainer.json` to use this image.

### Resource Limits

```bash
docker run -p 4096:4096 \
  --memory=4g \
  --cpus=2 \
  opencode-webui-workspace:latest
```
