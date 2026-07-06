#!/bin/bash
# ==============================================================================
# NEOS PLATFORM - AUTOMATED DEPLOYMENT ROLLBACK RUNNER
# ==============================================================================
# Reverts the active symlink to the previous healthy release and redeploys it.
# Usage: ./rollback.sh

set -e
set -o pipefail

BASE_DIR="/srv/neos"
RELEASES_DIR="$BASE_DIR/releases"
CURRENT_LINK="$BASE_DIR/current"

echo "=========================================================================="
echo "=== Starting Infrastructure Rollback..."
echo "=========================================================================="

# 1. Get current active release
if [ ! -L "$CURRENT_LINK" ]; then
    echo "ERROR: Current release symlink $CURRENT_LINK does not exist. Cannot rollback."
    exit 1
fi
ACTIVE_RELEASE=$(readlink -f "$CURRENT_LINK")
echo "Current active release: $ACTIVE_RELEASE"

# 2. Get list of available releases, sorted by modification time (newest first)
# We want the second newest folder in the list
PREV_RELEASE_PATH=$(ls -1td "$RELEASES_DIR"/* 2>/dev/null | sed -n '2p')

if [ -z "$PREV_RELEASE_PATH" ] || [ ! -d "$PREV_RELEASE_PATH" ]; then
    echo "ERROR: Previous release directory not found. Rollback impossible."
    exit 1
fi

echo "Previous healthy release found: $PREV_RELEASE_PATH"

# Confirm action (unless run inside automated environment like CI)
if [ -t 0 ]; then
    read -p "Rollback to $(basename "$PREV_RELEASE_PATH")? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Rollback cancelled."
        exit 1
    fi
fi

# 3. Perform atomic symlink revert
echo "Reverting symlink to previous release..."
ln -sfn "$PREV_RELEASE_PATH" "$BASE_DIR/current_tmp"
mv -Tf "$BASE_DIR/current_tmp" "$CURRENT_LINK"

echo "Active symlink reverted: $CURRENT_LINK -> $(readlink $CURRENT_LINK)"

# 4. Redeploy compose stacks from the reverted folder
echo "Restarting containers from previous release configs..."
cd "$PREV_RELEASE_PATH"
# Run make up on the previous release files
make up-apps

# 5. Optional: delete the failed release to clean up
echo "Failed release is left at $ACTIVE_RELEASE for diagnostics."
echo "If you wish to remove it, run: rm -rf $ACTIVE_RELEASE"

echo "=========================================================================="
echo "=== [SUCCESS] Rollback completed to $(basename "$PREV_RELEASE_PATH")! ==="
echo "=========================================================================="
