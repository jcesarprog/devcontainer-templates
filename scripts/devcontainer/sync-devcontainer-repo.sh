#!/usr/bin/env bash

# ============================================================================
# DevContainer Template Sync Script
# ============================================================================
#
# Syncs .devcontainer and scripts/devcontainer folders to a separate repository.
# Each template is stored in its own isolated branch for clean separation.
# The main branch is automatically updated with an index of all templates.
#
# USAGE:
#   ./scripts/devcontainer/sync-devcontainer-repo.sh <template-branch-name> [remote-repo-url]
#
# ARGUMENTS:
#   template-branch-name  Required. Name of the branch for this template
#   remote-repo-url       Optional. Defaults to: https://github.com/jcesarprog/devcontainer-templates.git
#
# EXAMPLES:
#   # Sync to default repository
#   ./scripts/devcontainer/sync-devcontainer-repo.sh nextjs-bun
#
#   # Sync to custom repository
#   ./scripts/devcontainer/sync-devcontainer-repo.sh nextjs-bun https://github.com/user/templates.git
#
#   # Backward compatible (URL first)
#   ./scripts/devcontainer/sync-devcontainer-repo.sh https://github.com/user/templates.git nextjs-bun
#
# WHAT IT DOES:
#   1. Creates/updates a branch with your devcontainer configuration
#   2. Pushes the template branch to the remote repository
#   3. Automatically updates the main branch with an index README
#   4. Lists all available templates with clone commands
#
# REPOSITORY STRUCTURE:
#   main branch        → Index README with all available templates
#   nextjs-bun branch  → Next.js + Bun devcontainer template
#   python-django      → Python Django devcontainer template
#   react-vite         → React + Vite devcontainer template
#   ...etc
#
# ============================================================================

set -e

# Default repository
DEFAULT_REPO="https://github.com/jcesarprog/devcontainer-templates.git"

# Parse arguments - support both orders for flexibility
if [ -z "$1" ]; then
    echo "Error: Template branch name is required"
    echo "Usage: $0 <template-branch-name> [remote-repo-url]"
    echo ""
    echo "Examples:"
    echo "  $0 nextjs-bun"
    echo "  $0 nextjs-bun https://github.com/user/devcontainer-templates.git"
    echo "  $0 python-django"
    echo "  $0 react-vite"
    echo ""
    echo "Default repository: $DEFAULT_REPO"
    echo ""
    echo "Each template will be stored in its own branch."
    echo "The main branch will automatically be updated with an index of all templates."
    exit 1
fi

# Check if first arg looks like a URL (contains ://)
if [[ "$1" == *"://"* ]]; then
    # Old format: repo url first, then branch
    REMOTE_REPO="${1}"
    TEMPLATE_BRANCH="${2}"
    if [ -z "$TEMPLATE_BRANCH" ]; then
        echo "Error: Template branch name is required"
        exit 1
    fi
else
    # New format: branch first, optional repo second
    TEMPLATE_BRANCH="${1}"
    REMOTE_REPO="${2:-$DEFAULT_REPO}"
fi

# Detect source workspace directory FIRST (before changing directories)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_WORKSPACE="$(cd "$SCRIPT_DIR/../.." && pwd)"

TEMP_DIR="/tmp/devcontainer-repo-$$"

echo "🔄 Syncing devcontainer template to repository..."
echo "   Remote: $REMOTE_REPO"
echo "   Template Branch: $TEMPLATE_BRANCH"
echo "   Source: $SOURCE_WORKSPACE"
echo ""

# Verify source directories exist
if [ ! -d "$SOURCE_WORKSPACE/.devcontainer" ]; then
    echo "❌ Error: .devcontainer directory not found in $SOURCE_WORKSPACE"
    exit 1
fi

if [ ! -d "$SOURCE_WORKSPACE/scripts/devcontainer" ]; then
    echo "❌ Error: scripts/devcontainer directory not found in $SOURCE_WORKSPACE"
    exit 1
fi

# Create temporary directory
rm -rf "$TEMP_DIR"
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"

# Clone or initialize the repo
REPO_EXISTS=false
if git ls-remote "$REMOTE_REPO" &>/dev/null; then
    echo "📥 Cloning existing repository..."
    git clone "$REMOTE_REPO" .
    REPO_EXISTS=true
else
    echo "📝 Initializing new repository..."
    git init
    git remote add origin "$REMOTE_REPO"
fi

# Check out or create the template branch
echo "🌿 Switching to template branch: $TEMPLATE_BRANCH"
if $REPO_EXISTS && git ls-remote --exit-code --heads origin "$TEMPLATE_BRANCH" &>/dev/null; then
    echo "   Branch exists, checking out and pulling latest..."
    git checkout "$TEMPLATE_BRANCH"
    git pull origin "$TEMPLATE_BRANCH" || echo "   No changes to pull"

    # Clean all tracked files in the branch to ensure fresh sync
    echo "   Cleaning existing files for fresh sync..."
    git rm -rf . 2>/dev/null || true
else
    echo "   Creating new orphan branch..."
    # Create orphan branch (no shared history with other templates)
    git checkout --orphan "$TEMPLATE_BRANCH"
    git rm -rf . 2>/dev/null || true
fi

# Ensure clean state - remove any untracked files too
rm -rf .devcontainer scripts README.md .gitignore 2>/dev/null || true

# Copy the devcontainer files to the root of this branch
echo "📋 Copying devcontainer files from source workspace..."
mkdir -p .devcontainer
mkdir -p scripts/devcontainer

# Copy with verbose output to confirm what's being synced
if [ -d "$SOURCE_WORKSPACE/.devcontainer" ]; then
    cp -r "$SOURCE_WORKSPACE/.devcontainer"/* .devcontainer/
    echo "   ✓ Copied .devcontainer/"
else
    echo "   ⚠ Warning: .devcontainer/ not found in source"
fi

if [ -d "$SOURCE_WORKSPACE/scripts/devcontainer" ]; then
    cp -r "$SOURCE_WORKSPACE/scripts/devcontainer"/* scripts/devcontainer/
    echo "   ✓ Copied scripts/devcontainer/"
else
    echo "   ⚠ Warning: scripts/devcontainer/ not found in source"
fi

# Create .gitignore with helpful defaults
echo "📝 Creating .gitignore for template..."
cat > .gitignore <<'GITIGNORE'
# DevContainer cache directory (automatically managed)
# Note: This is typically already covered by node_modules/ ignore,
# but we're explicit here for clarity
node_modules/.cache-deps/

# Common patterns you might want to add to your project:
# node_modules/
# .env
# .env.local
# dist/
# build/
# .DS_Store
GITIGNORE

# Create template-specific README
TEMPLATE_NAME_PRETTY=$(echo "$TEMPLATE_BRANCH" | sed 's/-/ /g' | sed 's/\b\(.\)/\u\1/g')
cat > README.md <<EOF
# $TEMPLATE_NAME_PRETTY DevContainer Template

DevContainer configuration for $TEMPLATE_NAME_PRETTY projects.

## 📁 Structure

- \`.devcontainer/\` - DevContainer configuration files
  - \`devcontainer.json\` - Main configuration
  - \`Dockerfile\` - Container image definition
  - \`.dockerignore\` - Docker build ignore rules
- \`scripts/devcontainer/\` - DevContainer setup scripts
  - \`postCreateContainer.sh\` - Post-creation setup script
  - \`sync-devcontainer-repo.sh\` - Script to sync this template back to repo

## 🚀 Quick Start

### Option 1: Clone this branch directly
\`\`\`bash
# Clone just this template branch
git clone -b $TEMPLATE_BRANCH --single-branch $REMOTE_REPO your-project-name
cd your-project-name

# Remove git history to start fresh (optional)
rm -rf .git
git init

# Open in VS Code
code .
\`\`\`

### Option 2: Copy to existing project
\`\`\`bash
# From your project directory
git clone -b $TEMPLATE_BRANCH --depth=1 $REMOTE_REPO temp-devcontainer
cp -r temp-devcontainer/.devcontainer .
cp -r temp-devcontainer/scripts .
rm -rf temp-devcontainer

# Open in VS Code - it will detect the devcontainer
code .
\`\`\`

## 📋 Requirements

- Docker Desktop or Docker Engine
- VS Code with [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)

## 📝 Last Updated

$(date '+%Y-%m-%d %H:%M:%S')

---

View all available templates on the [main branch](../../tree/main).
EOF

# Commit and push template branch
echo "💾 Committing template branch changes..."
git add .

TEMPLATE_UPDATED=false
if git diff --cached --quiet; then
    echo "✅ No changes to commit on template branch"
else
    # Generate detailed commit message
    CHANGED_FILES=$(git diff --cached --name-only | tr '\n' ', ' | sed 's/,$//')
    COMMIT_MSG="Update $TEMPLATE_BRANCH template

Updated: $CHANGED_FILES

Synced from: $SOURCE_WORKSPACE
Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"

    git commit -m "$COMMIT_MSG"
    echo "📤 Pushing template branch..."
    git push -u origin "$TEMPLATE_BRANCH"
    echo "✅ Template branch pushed successfully"
    echo "   Files updated: $CHANGED_FILES"
    TEMPLATE_UPDATED=true
fi

# Now update the main branch with an index of all templates
echo ""
echo "📚 Updating main branch index..."

# Fetch all remote branches
git fetch origin

# Check out or create main branch
if git ls-remote --exit-code --heads origin main &>/dev/null; then
    git checkout main
    git pull origin main
else
    git checkout --orphan main
    git rm -rf . 2>/dev/null || true
fi

# Get list of all template branches (exclude main)
BRANCHES=$(git branch -r | grep -v 'HEAD' | grep -v 'main' | sed 's/origin\///' | sed 's/^[[:space:]]*//' | sort)

# Generate main README with index
cat > README.md <<'MAINEOF'
# DevContainer Templates Collection

This repository contains various devcontainer configurations, each in its own branch. Each template is ready to use and includes all necessary configuration files.

## 📦 Available Templates

MAINEOF

# Add each branch to the README
if [ -n "$BRANCHES" ]; then
    while IFS= read -r branch; do
        # Format branch name for display
        display_name=$(echo "$branch" | sed 's/-/ /g' | sed 's/\b\(.\)/\u\1/g')
        echo "### 🔹 [$display_name]($REMOTE_REPO/tree/$branch)" >> README.md
        echo "" >> README.md
        echo "\`\`\`bash" >> README.md
        echo "# Clone this template" >> README.md
        echo "git clone -b $branch --single-branch $REMOTE_REPO your-project-name" >> README.md
        echo "" >> README.md
        echo "# Or copy to existing project" >> README.md
        echo "git clone -b $branch --depth=1 $REMOTE_REPO temp-devcontainer" >> README.md
        echo "cp -r temp-devcontainer/.devcontainer ." >> README.md
        echo "cp -r temp-devcontainer/scripts ." >> README.md
        echo "rm -rf temp-devcontainer" >> README.md
        echo "\`\`\`" >> README.md
        echo "" >> README.md
    done <<< "$BRANCHES"
else
    echo "*No templates available yet.*" >> README.md
    echo "" >> README.md
fi

# Add usage instructions
cat >> README.md <<'MAINEOF'

## 🚀 How to Use a Template

### Method 1: Clone Template Branch Directly (Recommended for new projects)

```bash
# Replace <template-branch> with your chosen template
git clone -b <template-branch> --single-branch <REPO_URL> my-project
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
git clone -b <template-branch> --depth=1 <REPO_URL> temp-devcontainer
cp -r temp-devcontainer/.devcontainer .
cp -r temp-devcontainer/scripts .
rm -rf temp-devcontainer

# Open in VS Code - it will detect the devcontainer
code .
```

### Method 3: Use GitHub's Template Feature

1. Go to the branch page: `<REPO_URL>/tree/<template-branch>`
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

MAINEOF

# Add timestamp
echo "$(date '+%Y-%m-%d %H:%M:%S')" >> README.md
echo "" >> README.md

# Replace <REPO_URL> placeholder with actual URL
sed -i "s|<REPO_URL>|$REMOTE_REPO|g" README.md

# Commit and push main branch
git add README.md
if git diff --cached --quiet; then
    echo "✅ Main branch index is already up to date"
else
    git commit -m "Update templates index ($(date '+%Y-%m-%d %H:%M:%S'))"
    echo "📤 Pushing main branch..."
    git push -u origin main
    echo "✅ Main branch index updated successfully"
fi

# Cleanup
cd "$SOURCE_WORKSPACE"
rm -rf "$TEMP_DIR"

echo ""
echo "🎉 Done! Template '$TEMPLATE_BRANCH' is synced."
echo "📚 View all templates: $REMOTE_REPO"
echo "🌿 View this template: $REMOTE_REPO/tree/$TEMPLATE_BRANCH"
echo ""
echo "💡 Next steps:"
echo "   - Check the template branch to verify changes"
echo "   - The main branch index has been updated automatically"
if $TEMPLATE_UPDATED; then
    echo "   - ✅ Template was updated with new changes"
else
    echo "   - ℹ️  No changes detected (template is up to date)"
fi

