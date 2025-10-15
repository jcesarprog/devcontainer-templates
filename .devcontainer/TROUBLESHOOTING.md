# DevContainer Troubleshooting Guide

## Issue: `deno install` hangs with "waiting for file lock on node_modules directory"

### Symptoms

- Running `deno install` or `deno i` gets stuck
- Error message: "waiting for file lock on node_modules directory"
- Process blocks indefinitely until interrupted with Ctrl+C

### Root Cause

A stale `.deno.lock` file in `node_modules/.deno/.deno.lock` can prevent Deno from acquiring the necessary file lock to install dependencies. This can happen when:

- The container was stopped while Deno was installing packages
- A previous Deno process crashed or was forcefully terminated
- The Deno LSP held a lock that wasn't properly released

### Solution (Immediate Fix)

If you encounter this issue, run:

```bash
# Remove the stale lock file
rm -f node_modules/.deno/.deno.lock

# Then retry the installation
deno install

# If packages need build scripts, run:
deno install --allow-scripts=npm:@tailwindcss/oxide,npm:sharp,npm:unrs-resolver
```

### Permanent Fix

The `postCreateContainer.sh` script has been updated to automatically:

1. Remove stale lock files when the container is created
2. Run `deno install` properly during setup
3. Automatically allow build scripts for common native modules

Next time you rebuild the container, this issue should not occur.

### Additional Tips

#### Check for Running Processes

If the issue persists, check if any Deno processes are holding locks:

```bash
# Check for running Deno processes
ps aux | grep deno

# Check what's holding the lock file (requires lsof)
lsof node_modules/.deno/.deno.lock
```

#### Rebuild the Container

If issues persist after trying the above:

1. In VS Code, open the Command Palette (Ctrl/Cmd + Shift + P)
2. Run: "Dev Containers: Rebuild Container"
3. This will rebuild the container with the updated scripts

#### Manual Cleanup

If you need to completely clean the node_modules:

```bash
# Warning: This removes ALL dependencies
sudo rm -rf node_modules
deno install
```

## Other Common Issues

### Docker Volume Permissions

If you encounter permission errors with the `node_modules` volume:

```bash
# Fix ownership
sudo chown -R dev:dev node_modules
```

### Package Manager Detection

The setup script automatically detects your package manager. If it picks the wrong one:

1. Ensure you have the correct lock file (e.g., `deno.lock` for Deno)
2. Set `packageManager` field in `package.json`:
   ```json
   {
     "packageManager": "deno"
   }
   ```

### Cache Location Issues

All package manager caches are stored in `node_modules/.cache-deps/` for optimal performance. If you need to clear caches:

```bash
# Clear Deno cache
rm -rf node_modules/.cache-deps/deno

# Then reinstall
deno install
```

## Need More Help?

If you continue experiencing issues:

1. Check the container logs: Docker Desktop → Containers → [your-container] → Logs
2. Verify Docker volume health: `docker volume ls` and `docker volume inspect [volume-name]`
3. Try completely removing and recreating the Docker volume (Warning: this removes all dependencies)
