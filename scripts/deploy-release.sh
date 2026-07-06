#!/bin/bash
# ==============================================================================
# NEOS PLATFORM - ATOMIC RELEASE-BASED DEPLOYMENT RUNNER
# ==============================================================================
# Executed by the GHA deploy job as the 'nasim' user on the VPS.
set -e
set -o pipefail

BASE_DIR="/srv/neos"
RELEASES_DIR="$BASE_DIR/releases"
SHARED_DIR="$BASE_DIR/shared"
CURRENT_LINK="$BASE_DIR/current"
TMP_SRC="/srv/neos/tmp/deploy-src"

echo "=========================================================================="
echo "=== Starting Release Deployment..."
echo "=========================================================================="

# 1. Generate sequence-based release ID (e.g. 2026-07-06-001)
DATE_PREFIX=$(date +"%Y-%m-%d")
EXISTING_COUNT=$(find "$RELEASES_DIR" -maxdepth 1 -name "${DATE_PREFIX}-*" -type d 2>/dev/null | wc -l || echo 0)
NEXT_NUM=$(printf "%03d" $((EXISTING_COUNT + 1)))
RELEASE_ID="${DATE_PREFIX}-${NEXT_NUM}"
NEW_RELEASE_PATH="$RELEASES_DIR/$RELEASE_ID"

echo "Release ID: $RELEASE_ID"
echo "Target Path: $NEW_RELEASE_PATH"

# 2. Check deployment source directory
if [ ! -d "$TMP_SRC" ]; then
    echo "ERROR: Deployment source directory $TMP_SRC does not exist."
    echo "Ensure files were successfully uploaded before running this script."
    exit 1
fi

# 3. Create release directory and copy files
echo "Copying repository source to release directory..."
mkdir -p "$NEW_RELEASE_PATH"
cp -R "$TMP_SRC"/. "$NEW_RELEASE_PATH"/

# 4. Link shared assets
echo "Linking shared assets to current release..."
# Symlink .env from shared/ to release root
if [ -f "$SHARED_DIR/.env" ]; then
    ln -sf "$SHARED_DIR/.env" "$NEW_RELEASE_PATH/.env"
else
    echo "Warning: No shared .env file found in $SHARED_DIR. Deploying without linking .env."
fi

# 5. Run Compose Config Validation
echo "Validating Docker Compose configurations in release directory..."
cd "$NEW_RELEASE_PATH"
# Test the compose syntax
make config-check

# 6. Spin up new release containers
echo "Starting container stacks..."
# make up compiles all compose files relative to the new release path
make up-apps

# 7. Atomic symlink swap
echo "Performing atomic symlink swap..."
# Force creation of temporary link first, then rename it atomically to replace the current link
ln -sfn "$NEW_RELEASE_PATH" "$BASE_DIR/current_tmp"
mv -Tf "$BASE_DIR/current_tmp" "$CURRENT_LINK"

echo "Active release switched: $CURRENT_LINK -> $(readlink $CURRENT_LINK)"

# 8. Clean up staging folder
echo "Cleaning staging directory..."
rm -rf "$TMP_SRC"/*

# 9. Prune old releases (retain latest 5)
echo "Pruning older releases (retaining latest 5)..."
cd "$RELEASES_DIR"
# List directories in time-order, keep top 5, delete the rest
ls -1t | tail -n +6 | while read -r old_release; do
    if [ -n "$old_release" ]; then
        echo "Removing obsolete release: $old_release"
        rm -rf "$old_release"
    fi
done

echo "=========================================================================="
echo "=== [SUCCESS] Release $RELEASE_ID Deployed and Active! ==="
echo "=========================================================================="
