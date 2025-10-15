# DevContainer Templates Collection

This repository contains various devcontainer configurations, each in its own branch. Each template is ready to use and includes all necessary configuration files.

## 📦 Available Templates

### 🔹 [Next15 Deno](https://github.com/jcesarprog/devcontainer-templates.git/tree/next15-deno)

```bash
# Clone this template
git clone -b next15-deno --single-branch https://github.com/jcesarprog/devcontainer-templates.git your-project-name

# Or copy to existing project
git clone -b next15-deno --depth=1 https://github.com/jcesarprog/devcontainer-templates.git temp-devcontainer
cp -r temp-devcontainer/.devcontainer .
cp -r temp-devcontainer/scripts .
rm -rf temp-devcontainer
```

### 🔹 [Nextjs15 Bun](https://github.com/jcesarprog/devcontainer-templates.git/tree/nextjs15-bun)

```bash
# Clone this template
git clone -b nextjs15-bun --single-branch https://github.com/jcesarprog/devcontainer-templates.git your-project-name

# Or copy to existing project
git clone -b nextjs15-bun --depth=1 https://github.com/jcesarprog/devcontainer-templates.git temp-devcontainer
cp -r temp-devcontainer/.devcontainer .
cp -r temp-devcontainer/scripts .
rm -rf temp-devcontainer
```

### 🔹 [Nextjs15 Pnpm](https://github.com/jcesarprog/devcontainer-templates.git/tree/nextjs15-pnpm)

```bash
# Clone this template
git clone -b nextjs15-pnpm --single-branch https://github.com/jcesarprog/devcontainer-templates.git your-project-name

# Or copy to existing project
git clone -b nextjs15-pnpm --depth=1 https://github.com/jcesarprog/devcontainer-templates.git temp-devcontainer
cp -r temp-devcontainer/.devcontainer .
cp -r temp-devcontainer/scripts .
rm -rf temp-devcontainer
```

### 🔹 [Whitesource/Configure](https://github.com/jcesarprog/devcontainer-templates.git/tree/whitesource/configure)

```bash
# Clone this template
git clone -b whitesource/configure --single-branch https://github.com/jcesarprog/devcontainer-templates.git your-project-name

# Or copy to existing project
git clone -b whitesource/configure --depth=1 https://github.com/jcesarprog/devcontainer-templates.git temp-devcontainer
cp -r temp-devcontainer/.devcontainer .
cp -r temp-devcontainer/scripts .
rm -rf temp-devcontainer
```


## 🚀 How to Use a Template

### Method 1: Clone Template Branch Directly (Recommended for new projects)

```bash
# Replace <template-branch> with your chosen template
git clone -b <template-branch> --single-branch https://github.com/jcesarprog/devcontainer-templates.git my-project
cd my-project

# Optional: Remove git history to start fresh
rm -rf .git
git init

# Open in VS Code
code .
```

### Method 2: Add to Existing Project

```bash
# From your project root
git clone -b <template-branch> --depth=1 https://github.com/jcesarprog/devcontainer-templates.git temp-devcontainer
cp -r temp-devcontainer/.devcontainer .
cp -r temp-devcontainer/scripts .
rm -rf temp-devcontainer

# Open in VS Code - it will detect the devcontainer
code .
```

### Method 3: Use GitHub's Template Feature

1. Go to the branch page: `https://github.com/jcesarprog/devcontainer-templates.git/tree/<template-branch>`
2. Click "Use this template" button
3. Create your new repository
4. Clone and open in VS Code

## 📋 Requirements

- **Docker Desktop** or Docker Engine
- **VS Code** with [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)

## 🔄 Contributing Templates

Each template is maintained in its own branch. To contribute or update a template:

1. Clone the specific template branch
2. Make your changes
3. Push back to the same branch
4. The main branch index will update automatically

## 📝 Template Structure

Each template branch contains:

- `.devcontainer/` - DevContainer configuration
  - `devcontainer.json` - Container settings
  - `Dockerfile` - Image definition
  - `.dockerignore` - Build exclusions
- `scripts/devcontainer/` - Setup scripts
  - `postCreateContainer.sh` - Post-creation tasks
  - `sync-devcontainer-repo.sh` - Sync utility

## 📅 Last Updated

2025-10-15 14:59:43

