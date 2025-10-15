FROM denoland/deno:alpine-2.5.4

# Remove problematic libgcc_s.so.1 from /usr/local/lib that conflicts with Alpine's native libraries
RUN rm -f /usr/local/lib/libgcc_s.so.1 /usr/local/lib/libstdc++.so.* /usr/local/lib/libgcc_s.so || true

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
    # Install Node.js (needed for Next.js alongside Deno)
    apk add --no-cache nodejs npm && \
    # Verify all tools are working
    deno --version && \
    node --version && \
    npm --version && \
    # Rename existing deno user to dev and update home directory
    usermod -l dev deno && \
    groupmod -n dev deno && \
    usermod -d /home/dev -m dev && \
    # Change shell to bash for dev user
    usermod -s /bin/bash dev && \
    # Enable dev user to use sudo
    echo "dev ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/dev && \
    chmod 0440 /etc/sudoers.d/dev

# Using the dev user (non-root)
USER dev
