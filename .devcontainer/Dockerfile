FROM oven/bun:1.3.0-alpine

RUN apk add --no-cache \
    # Core utilities
    git \
    bash \
    curl \
    wget \
    sudo \
    shadow \
    # Docker CLI (to communicate with host Docker daemon)
    docker-cli \
    # GitHub CLI for easy authentication
    github-cli \
    # Build tools (for native node modules)
    python3 \
    make \
    g++ \
    # Text editors
    vim \
    # Process/system tools
    procps \
    htop \
    # SSH and certificates
    openssh-client \
    ca-certificates \
    # JSON/text processing
    jq \
    grep \
    sed && \
    # Rename existing bun user to dev and update home directory
    usermod -l dev bun && \
    groupmod -n dev bun && \
    usermod -d /home/dev -m dev && \
    # Change shell to bash for dev user (bun uses ash by default)
    usermod -s /bin/bash dev && \
    # Enable dev user to use sudo
    echo "dev ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/dev && \
    chmod 0440 /etc/sudoers.d/dev

# Using the dev user (non-root)
USER dev
