# OpenCode WebUI Workspace

A containerized development environment running OpenCode WebUI with
comprehensive tooling support. This Docker image includes Python, Node.js, Bun,
Go, Rust, and essential development tools, all running under a non-root
`opencode` user with sudo privileges.

## Features

- **OpenCode WebUI** (v1.1.25) - AI-powered code editor
- **Lightweight Architecture**: Based on `python:3.13-slim-bookworm` (Debian)
  for maximum efficiency on Railway.
- **Python 3.13** (Pre-installed)
- **Node.js 24.x (LTS)**
- **Bun 1.3.x**
- **Go 1.23.5**
- **Rust 1.92.x**
- **uv** Python package manager
- **Non-root user** (`opencode`) with passwordless sudo access
- **Pre-configured workspace** at `/home/opencode/workspace`

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
OPENCODE_SERVER_USERNAME=opencode
OPENCODE_SERVER_PASSWORD=your-secure-password-here
OPENCODE_PORT=4096
OPENCODE_HOSTNAME=0.0.0.0
```

- **OPENCODE_SERVER_USERNAME**: Default login username (default: `opencode`)
- **OPENCODE_SERVER_PASSWORD**: Secure password for the server (required for
  authentication)
- **OPENCODE_PORT**: Port to listen on (default: 4096)
- **OPENCODE_HOSTNAME**: Hostname/IP to bind to (default: 0.0.0.0)

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

## Railway Deployment (Guides)

There are two ways to deploy this environment on Railway:

### Option A: The "Fast" Way (Using Pre-built Image) 🚀

This method is incredibly fast because it downloads the pre-compiled Docker
image from GitHub instead of building everything from scratch.

1. In Railway, click **+ New** > **Docker Image**.
2. Enter the image URL: `ghcr.io/YOUR_GITHUB_USER/opencode-webui:latest`
   (replace with your actual GitHub username).
3. Under **Variables**, add:
   - `OPENCODE_SERVER_PASSWORD`: Your password.
   - `PORT`: `4096` _(Mandatory. `railway.json` is ignored for external
     images)._
   - `GITHUB_REPO_URL`: URL of the code you want the AI to work on.
   - `GITHUB_TOKEN`: Your GitHub token for the "Auto-Save" AI skill.
4. Under **Volumes**, add a new volume mounted precisely at
   `/home/opencode/workspace`.
5. Under **Networking**, click **Generate Domain** so you can access the
   interface.

### Option B: The "Source" Way (Fork & Deploy) 🛠️

This method builds the Docker image directly on Railway. It is slower (5-8 mins)
but automatically configures the network via `railway.json`.

1. Click the button at the top of this README, or connect your GitHub fork as a
   new Railway Project.
2. Railway will read `railway.json` and automatically set up the port and
   deployment rules.
3. Add the same **Variables** and **Volume** (`/home/opencode/workspace`) as
   above.

> [!TIP]
> **Free Plan User?** For Option A, ensure **Sleep Application** is enabled in
> your Service Settings on Railway to comply with Free Plan serverless
> requirements. Option B handles this automatically via `railway.json`.

---
**That's it!** Once the deployment is finished:

1. Open your Railway URL.
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
