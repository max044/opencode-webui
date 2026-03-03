FROM python:3.13-slim-bookworm

ENV DEBIAN_FRONTEND=noninteractive
ENV PORT=4096

# 1. System Dependencies + Node.js + MongoDB + Go
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl wget git build-essential ca-certificates unzip zip jq htop tmux openssh-client rclone sudo gnupg && \
    # MongoDB 7.0
    curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | gpg --dearmor -o /usr/share/keyrings/mongodb-server-7.0.gpg && \
    echo "deb [ signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] http://repo.mongodb.org/apt/debian bookworm/mongodb-org/7.0 main" | tee /etc/apt/sources.list.d/mongodb-org-7.0.list && \
    apt-get update && apt-get install -y --no-install-recommends mongodb-org && \
    # Node.js
    curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - && \
    apt-get install -y --no-install-recommends nodejs && \
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

# 2. User Creation
RUN useradd -m -s /bin/bash opencode && \
    echo "opencode ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/opencode

# 3. Install tools and move them to /opt/ (so they aren't hidden by volume)
ENV RUSTUP_HOME=/opt/rust/rustup
ENV CARGO_HOME=/opt/rust/cargo
ENV BUN_INSTALL=/opt/bun
ENV UV_INSTALL_DIR=/opt/uv

RUN mkdir -p /opt/rust /opt/bun /opt/uv /opt/opencode/bin && \
    chown -R opencode:opencode /opt/rust /opt/bun /opt/uv /opt/opencode

USER opencode
RUN curl -fsSL https://bun.sh/install | bash && \
    curl -LsSf https://astral.sh/uv/install.sh | sh && \
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y && \
    # Install opencode and move it to /opt/opencode
    curl -fsSL https://opencode.ai/install | bash && \
    # The install script usually puts it in /home/opencode/.local/bin/opencode or /home/opencode/.opencode/bin/opencode
    mv /home/opencode/.opencode/bin/opencode /opt/opencode/bin/opencode || \
    mv /home/opencode/.local/bin/opencode /opt/opencode/bin/opencode

# 4. PATH
ENV PATH="/opt/opencode/bin:/opt/bun/bin:/opt/rust/cargo/bin:/opt/uv:/usr/local/go/bin:${PATH}"

# 5. Automation Scripts
USER root
COPY setup.sh /usr/local/bin/setup.sh
COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/setup.sh /usr/local/bin/start.sh && \
    mkdir -p /var/lib/mongodb && \
    chown -R opencode:opencode /var/lib/mongodb /var/log/mongodb

USER opencode
WORKDIR /home/opencode
EXPOSE ${PORT}

CMD ["bash", "/usr/local/bin/start.sh"]
