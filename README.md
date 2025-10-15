# Nextjs15 Bun DevContainer Template

DevContainer configuration for Nextjs15 Bun projects.

## 📁 Structure

- `.devcontainer/` - DevContainer configuration files
  - `devcontainer.json` - Main configuration
  - `Dockerfile` - Container image definition
  - `.dockerignore` - Docker build ignore rules
- `scripts/devcontainer/` - DevContainer setup scripts
  - `postCreateContainer.sh` - Post-creation setup script
  - `sync-devcontainer-repo.sh` - Script to sync this template back to repo

## 🚀 Quick Start

### Option 1: Clone this branch directly
```bash
# Clone just this template branch
git clone -b nextjs15-bun --single-branch https://github.com/jcesarprog/devcontainer-templates.git your-project-name
cd your-project-name

# Remove git history to start fresh (optional)
rm -rf .git
git init

# Open in VS Code
code .
```

### Option 2: Copy to existing project
```bash
# From your project directory
git clone -b nextjs15-bun --depth=1 https://github.com/jcesarprog/devcontainer-templates.git temp-devcontainer
cp -r temp-devcontainer/.devcontainer .
cp -r temp-devcontainer/scripts .
rm -rf temp-devcontainer

# Open in VS Code - it will detect the devcontainer
code .
```

## 📋 Requirements

- Docker Desktop or Docker Engine
- VS Code with [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)

## 📝 Last Updated

2025-10-15 11:58:21

---

View all available templates on the [main branch](../../tree/main).
