#!/usr/bin/env bash

# Post-create container setup script
# This script is IDEMPOTENT - safe to run multiple times without side effects.
# Each function checks if its configuration is already applied before making changes.

# Color output utility functions
function success() {
    echo -e "\033[0;32m✓ $1\033[0m"
}

function warning() {
    echo -e "\033[0;33m⚠ $1\033[0m"
}

function error() {
    echo -e "\033[0;31m✗ $1\033[0m"
}

function info() {
    echo -e "\033[0;36mℹ $1\033[0m"
}

function setup_workspace_dirs(){
    # Check if node_modules is mounted (volume mount point)
    if [ -d /workspaces/nextjs-test/node_modules ]; then
        # Fix ownership of the Docker volume
        sudo chown -R dev:dev /workspaces/nextjs-test/node_modules 2>/dev/null || true

        # Create .bun-cache directory inside node_modules (same filesystem = hardlinks work!)
        mkdir -p /workspaces/nextjs-test/node_modules/.bun-cache

        info "Workspace directories already set up correctly"
        return 0
    fi

    # This shouldn't happen if volume is mounted correctly
    warning "node_modules volume not mounted - check devcontainer.json"
    return 1
}

function setup_docker_access(){
    # Enable Docker CLI access to host Docker daemon
    if [ -S /var/run/docker.sock ]; then
        DOCKER_GID=$(stat -c '%g' /var/run/docker.sock)

        # Check if already configured
        if [ "$DOCKER_GID" -eq 0 ]; then
            # Root-owned socket - check permissions
            if [ -w /var/run/docker.sock ]; then
                info "Docker socket access already configured (root-owned)"
                return 0
            fi
        else
            # Check if user is already in docker group and group exists with correct GID
            if getent group docker > /dev/null 2>&1 && \
               groups dev | grep -q docker && \
               [ "$(getent group docker | cut -d: -f3)" = "$DOCKER_GID" ]; then
                info "Docker access already configured (user in docker group)"
                return 0
            fi
        fi

        info "Configuring Docker socket access (GID: ${DOCKER_GID})..."

        if [ "$DOCKER_GID" -eq 0 ]; then
            # Socket owned by root group - just fix permissions
            sudo chmod 666 /var/run/docker.sock
            echo "  → Docker socket permissions updated (root-owned socket)"
        else
            # Socket owned by docker group - add user to that group
            if ! getent group docker > /dev/null 2>&1; then
                sudo groupadd -g ${DOCKER_GID} docker
            fi
            sudo usermod -aG docker dev
            echo "  → User added to docker group (GID: ${DOCKER_GID})"
        fi

        success "Docker access configured successfully"
    else
        warning "Docker socket not found - skipping Docker setup"
    fi
}

function install_deps(){
    # Configure Bun to use cache inside node_modules volume
    # Both cache and packages are in the same volume = hardlinks work!
    export BUN_INSTALL_CACHE_DIR=/workspaces/nextjs-test/node_modules/.bun-cache

    # Check if dependencies are already installed and up to date
    if [ -d /workspaces/nextjs-test/node_modules/.bun-cache ] || \
       [ -n "$(ls -A /workspaces/nextjs-test/node_modules 2>/dev/null | grep -v '^\.bun-cache$')" ]; then
        # Check if lockfile is newer than node_modules (meaning deps need update)
        if [ -f bun.lockb ] && [ bun.lockb -nt /workspaces/nextjs-test/node_modules ]; then
            info "Dependencies outdated, reinstalling..."
        else
            info "Dependencies already installed and up to date"
            return 0
        fi
    fi

    # Install dependencies with Bun
    if bun install; then
        success "Dependencies installed successfully with Bun (using hardlinks)"
    else
        error "Failed to install dependencies"
        return 1
    fi
}

function activate_aliases(){
    # Enable colored ls output by default
    if ! grep -q "alias ls=" ~/.bash_aliases 2>/dev/null; then
        echo "alias ls='ls --color=auto'" >> ~/.bash_aliases
        info "Added colored 'ls' alias"
    fi

    # Add ll alias for detailed listing
    if ! grep -q "alias ll=" ~/.bash_aliases 2>/dev/null; then
        echo "alias ll='ls -lah --color=auto'" >> ~/.bash_aliases
        info "Added 'll' alias (detailed list)"
    fi

    # Add la alias for showing hidden files
    if ! grep -q "alias la=" ~/.bash_aliases 2>/dev/null; then
        echo "alias la='ls -A --color=auto'" >> ~/.bash_aliases
        info "Added 'la' alias (show hidden files)"
    fi

    # Enable colored grep output
    if ! grep -q "alias grep=" ~/.bash_aliases 2>/dev/null; then
        echo "alias grep='grep --color=auto'" >> ~/.bash_aliases
        info "Added colored 'grep' alias"
    fi
    # Add ralias for easier alias reload
    if ! grep -q "alias ralias=" ~/.bash_aliases 2>/dev/null; then
        echo "alias ralias='source ~/.bash_aliases'" >> ~/.bash_aliases
        info "Added 'ralias' alias"
    fi

    # Check if vim is installed and create alias
    if command -v vim &> /dev/null && ! grep -q "alias vi=" ~/.bash_aliases 2>/dev/null; then
        echo "alias vi=vim" >> ~/.bash_aliases
        info "Added 'vi' alias for vim"
    fi



    # Load bash aliases if they exist
    if [ -f ~/.bash_aliases ]; then
        source ~/.bash_aliases
        success "Aliases loaded"
        if ! grep -q "source ~/.bash_aliases" ~/.bashrc 2>/dev/null; then
            echo "source ~/.bash_aliases" >> ~/.bashrc
            success "Aliases added into ~/.bashrc"
        fi
    else
        warning "No .bash_aliases file found"
    fi
}

function main(){
    setup_workspace_dirs
    setup_docker_access
    install_deps
    activate_aliases
}

main
