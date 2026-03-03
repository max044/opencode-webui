FROM python:3.13-slim-bookworm

ENV DEBIAN_FRONTEND=noninteractive
ENV PORT=4096

# 1. Dépendances système + Node.js + Cloudflared + Go (single root layer)
RUN apt-get update && \
    curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - && \
    apt-get install -y --no-install-recommends \
    curl wget git build-essential ca-certificates unzip zip jq htop tmux openssh-client rclone sudo nodejs && \
    # Cloudflared
    ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then CLOUD_ARCH="amd64"; else CLOUD_ARCH="arm64"; fi && \
    curl -L "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${CLOUD_ARCH}.deb" -o cloudflared.deb && \
    dpkg -i cloudflared.deb && rm cloudflared.deb && \
    # Go
    case "$(uname -m)" in \
    aarch64) GOARCH='arm64' ;; \
    x86_64) GOARCH='amd64' ;; \
    *) echo "Unsupported architecture"; exit 1 ;; \
    esac && \
    wget -q https://go.dev/dl/go1.23.5.linux-${GOARCH}.tar.gz && \
    tar -C /usr/local -xzf go1.23.5.linux-${GOARCH}.tar.gz && \
    rm go1.23.5.linux-${GOARCH}.tar.gz && \
    # Cleanup
    apt-get clean && rm -rf /var/lib/apt/lists/*

# 2. Création de l'utilisateur
RUN useradd -m -s /bin/bash opencode && \
    echo "opencode ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/opencode

# Configuration du PATH
ENV PATH="/home/opencode/.local/bin:/home/opencode/.cargo/bin:/home/opencode/.bun/bin:/usr/local/go/bin:${PATH}"

# 3. Outils utilisateur (Bun, UV, Rust, OpenCode) — single user layer
USER opencode
RUN curl -fsSL https://bun.sh/install | bash && \
    curl -LsSf https://astral.sh/uv/install.sh | sh && \
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y && \
    curl -fsSL https://opencode.ai/install | bash

# 4. Automation Scripts
USER root
COPY setup.sh /usr/local/bin/setup.sh
COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/setup.sh /usr/local/bin/start.sh

USER opencode
WORKDIR /home/opencode/workspace
EXPOSE ${PORT}

CMD ["bash", "/usr/local/bin/start.sh"]
