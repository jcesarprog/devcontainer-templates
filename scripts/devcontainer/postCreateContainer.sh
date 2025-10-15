#!/usr/bin/env bash

# ============================================================================
# Post-create Container Setup Script
# ============================================================================
#
# This script is IDEMPOTENT - safe to run multiple times without side effects.
# Each function checks if its configuration is already applied before making changes.
#
# FEATURES:
#   - Auto-detects package manager (bun, pnpm, npm, deno)
#   - Configures optimized caching for each package manager
#   - Sets up Docker access for the dev user
#   - Installs dependencies automatically
#   - Configures useful shell aliases
#
# PACKAGE MANAGER SUPPORT:
#   Bun   - Detects bun.lockb, uses hardlink-optimized cache
#   pnpm  - Detects pnpm-lock.yaml, uses content-addressable store
#   npm   - Detects package-lock.json, uses traditional cache
#   Deno  - Detects deno.json/deno.jsonc, uses module cache
#
# CACHE LOCATIONS:
#   All caches are stored in node_modules/.cache-deps/<package-manager>
#   Both packages and caches are in the same Docker volume for:
#     - Persistence across container rebuilds
#     - Better performance than bind mounts
#     - Hardlink support - same filesystem enables hardlinks (bun, pnpm)
#     - Single volume simplicity
#
# ============================================================================

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

function detect_package_manager(){
    # Auto-detect package manager based on multiple indicators

    # 1. Check package.json for explicit packageManager field (most reliable)
    if [ -f "package.json" ]; then
        # Extract packageManager field if it exists
        PKG_MGR_FIELD=$(grep -o '"packageManager"[[:space:]]*:[[:space:]]*"[^"]*"' package.json 2>/dev/null | cut -d'"' -f4 | cut -d'@' -f1)
        if [ -n "$PKG_MGR_FIELD" ]; then
            echo "$PKG_MGR_FIELD"
            return 0
        fi
    fi

    # 2. Check for lockfiles (both old and new formats)
    # Bun uses both bun.lockb (old) and bun.lock (new)
    if [ -f "bun.lockb" ] || [ -f "bun.lock" ]; then
        echo "bun"
    elif [ -f "pnpm-lock.yaml" ]; then
        echo "pnpm"
    elif [ -f "yarn.lock" ]; then
        echo "yarn"
    elif [ -f "package-lock.json" ]; then
        echo "npm"
    elif [ -f "deno.json" ] || [ -f "deno.jsonc" ] || [ -f "deno.lock" ]; then
        echo "deno"
    elif [ -f "package.json" ]; then
        # 3. If package.json exists but no lockfile, check which package manager is available
        if command -v bun &> /dev/null; then
            echo "bun"
        elif command -v pnpm &> /dev/null; then
            echo "pnpm"
        elif command -v yarn &> /dev/null; then
            echo "yarn"
        elif command -v npm &> /dev/null; then
            echo "npm"
        else
            # Last resort: default to npm
            echo "npm"
        fi
    else
        echo "unknown"
    fi
}

function setup_workspace_dirs(){
    # Detect package manager
    PKG_MANAGER=$(detect_package_manager)

    # Get the workspace root (parent directory of the script)
    WORKSPACE_ROOT="$(cd "$(dirname "$(dirname "$(dirname "${BASH_SOURCE[0]}")")")" && pwd)"

    # Fix ownership of the Docker volume
    if [ -d "$WORKSPACE_ROOT/node_modules" ]; then
        sudo chown -R dev:dev "$WORKSPACE_ROOT/node_modules" 2>/dev/null || true
    fi

    # Create cache directory structure inside node_modules
    mkdir -p "$WORKSPACE_ROOT/node_modules/.cache-deps"

    # Configure package manager specific cache locations
    # All caches are inside node_modules/.cache-deps/ for hardlink efficiency
    case "$PKG_MANAGER" in
        bun)
            # Bun benefits from cache on same filesystem as node_modules for hardlinks
            mkdir -p "$WORKSPACE_ROOT/node_modules/.cache-deps/bun"
            export BUN_INSTALL_CACHE_DIR="$WORKSPACE_ROOT/node_modules/.cache-deps/bun"
            info "Configured for Bun (hardlink-optimized cache)"
            ;;
        pnpm)
            # pnpm uses a content-addressable store, benefits from hardlinks
            mkdir -p "$WORKSPACE_ROOT/node_modules/.cache-deps/pnpm"
            export PNPM_HOME="$WORKSPACE_ROOT/node_modules/.cache-deps/pnpm"
            export npm_config_store_dir="$WORKSPACE_ROOT/node_modules/.cache-deps/pnpm/store"
            info "Configured for pnpm (content-addressable store with hardlinks)"
            ;;
        npm)
            # npm traditional cache
            mkdir -p "$WORKSPACE_ROOT/node_modules/.cache-deps/npm"
            export npm_config_cache="$WORKSPACE_ROOT/node_modules/.cache-deps/npm"
            info "Configured for npm (traditional cache)"
            ;;
        yarn)
            # yarn cache
            mkdir -p "$WORKSPACE_ROOT/node_modules/.cache-deps/yarn"
            export YARN_CACHE_FOLDER="$WORKSPACE_ROOT/node_modules/.cache-deps/yarn"
            info "Configured for yarn (cache folder)"
            ;;
        deno)
            # Deno uses its own cache directory
            mkdir -p "$WORKSPACE_ROOT/node_modules/.cache-deps/deno"
            export DENO_DIR="$WORKSPACE_ROOT/node_modules/.cache-deps/deno"
            info "Configured for Deno (module cache)"
            ;;
        *)
            warning "Package manager not detected, using default npm configuration"
            mkdir -p "$WORKSPACE_ROOT/node_modules/.cache-deps/npm"
            export npm_config_cache="$WORKSPACE_ROOT/node_modules/.cache-deps/npm"
            ;;
    esac

    success "Workspace directories configured for: $PKG_MANAGER"

    # Persist cache configuration to .bashrc for future sessions
    persist_cache_config "$PKG_MANAGER" "$WORKSPACE_ROOT"

    return 0
}

function persist_cache_config(){
    local pkg_manager="$1"
    local workspace_root="$2"
    local config_marker="# Package manager cache configuration (auto-generated)"

    # Remove old configuration if exists
    if grep -q "$config_marker" ~/.bashrc 2>/dev/null; then
        sed -i "/$config_marker/,+10d" ~/.bashrc
    fi

    # Add new configuration
    echo "" >> ~/.bashrc
    echo "$config_marker" >> ~/.bashrc

    case "$pkg_manager" in
        bun)
            echo "export BUN_INSTALL_CACHE_DIR=\"$workspace_root/node_modules/.cache-deps/bun\"" >> ~/.bashrc
            ;;
        pnpm)
            echo "export PNPM_HOME=\"$workspace_root/node_modules/.cache-deps/pnpm\"" >> ~/.bashrc
            echo "export npm_config_store_dir=\"$workspace_root/node_modules/.cache-deps/pnpm/store\"" >> ~/.bashrc
            echo 'export PATH="$PNPM_HOME:$PATH"' >> ~/.bashrc
            ;;
        npm)
            echo "export npm_config_cache=\"$workspace_root/node_modules/.cache-deps/npm\"" >> ~/.bashrc
            ;;
        yarn)
            echo "export YARN_CACHE_FOLDER=\"$workspace_root/node_modules/.cache-deps/yarn\"" >> ~/.bashrc
            ;;
        deno)
            echo "export DENO_DIR=\"$workspace_root/node_modules/.cache-deps/deno\"" >> ~/.bashrc
            ;;
    esac

    info "Cache configuration persisted to ~/.bashrc"
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
    # Detect package manager
    PKG_MANAGER=$(detect_package_manager)

    if [ "$PKG_MANAGER" = "unknown" ]; then
        info "No package.json or lock file found, skipping dependency installation"
        return 0
    fi

    # Get the workspace root (parent directory of the script)
    WORKSPACE_ROOT="$(cd "$(dirname "$(dirname "$(dirname "${BASH_SOURCE[0]}")")")" && pwd)"

    # Check if dependencies are already installed
    if [ -n "$(ls -A "$WORKSPACE_ROOT/node_modules" 2>/dev/null | grep -v '^\.cache-deps$')" ]; then
        # Determine lockfile based on package manager
        LOCKFILE=""
        case "$PKG_MANAGER" in
            bun)
                # Check for both old (bun.lockb) and new (bun.lock) formats
                if [ -f "bun.lock" ]; then
                    LOCKFILE="bun.lock"
                elif [ -f "bun.lockb" ]; then
                    LOCKFILE="bun.lockb"
                fi
                ;;
            pnpm) LOCKFILE="pnpm-lock.yaml" ;;
            npm) LOCKFILE="package-lock.json" ;;
            yarn) LOCKFILE="yarn.lock" ;;
            deno) LOCKFILE="deno.lock" ;;
        esac

        # Check if lockfile is newer than node_modules (meaning deps need update)
        if [ -n "$LOCKFILE" ] && [ -f "$LOCKFILE" ] && [ "$LOCKFILE" -nt "$WORKSPACE_ROOT/node_modules" ]; then
            info "Dependencies outdated, reinstalling..."
        else
            info "Dependencies already installed and up to date"
            return 0
        fi
    fi

    # Install dependencies with the appropriate package manager
    info "Installing dependencies with $PKG_MANAGER..."

    case "$PKG_MANAGER" in
        bun)
            if bun install; then
                success "Dependencies installed successfully with Bun (using hardlinks)"
            else
                error "Failed to install dependencies with Bun"
                return 1
            fi
            ;;
        pnpm)
            # Install pnpm if not available
            if ! command -v pnpm &> /dev/null; then
                info "Installing pnpm..."
                npm install -g pnpm
            fi
            if pnpm install; then
                success "Dependencies installed successfully with pnpm (content-addressable store)"
            else
                error "Failed to install dependencies with pnpm"
                return 1
            fi
            ;;
        npm)
            if npm install; then
                success "Dependencies installed successfully with npm"
            else
                error "Failed to install dependencies with npm"
                return 1
            fi
            ;;
        yarn)
            # Install yarn if not available
            if ! command -v yarn &> /dev/null; then
                info "Installing yarn..."
                npm install -g yarn
            fi
            if yarn install; then
                success "Dependencies installed successfully with yarn"
            else
                error "Failed to install dependencies with yarn"
                return 1
            fi
            ;;
        deno)
            # Remove stale Deno lock file in node_modules if it exists (prevents install blocking)
            if [ -f "$WORKSPACE_ROOT/node_modules/.deno/.deno.lock" ]; then
                rm -f "$WORKSPACE_ROOT/node_modules/.deno/.deno.lock"
                info "Removed stale Deno lock file"
            fi

            # Try to install dependencies using deno install
            if [ -f "deno.json" ] || [ -f "deno.jsonc" ]; then
                info "Installing Deno dependencies..."
                if deno install 2>/dev/null; then
                    success "Deno dependencies installed successfully"

                    # Check if there are packages that need build scripts
                    # Common packages that need build scripts: @tailwindcss/oxide, sharp, etc.
                    if [ -f "package.json" ]; then
                        info "Running Deno install with build scripts for native modules..."
                        deno install --allow-scripts=npm:@tailwindcss/oxide,npm:sharp,npm:unrs-resolver 2>/dev/null || true
                    fi
                else
                    warning "Deno install failed, dependencies will be cached on first run"
                fi
            elif deno cache --reload main.ts 2>/dev/null || deno cache --reload mod.ts 2>/dev/null; then
                success "Dependencies cached successfully with Deno"
            else
                info "Deno project detected, dependencies will be cached on first run"
            fi
            ;;
        *)
            warning "Unknown package manager, attempting npm install..."
            if npm install; then
                success "Dependencies installed with npm (fallback)"
            else
                error "Failed to install dependencies"
                return 1
            fi
            ;;
    esac
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
