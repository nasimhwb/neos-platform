#!/bin/bash
# ==============================================================================
# NEOS PLATFORM - BLUE-GREEN ZERO-DOWNTIME DEPLOYMENT RUNNER
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
echo "=== Starting Zero-Downtime Blue-Green Deployment..."
echo "=========================================================================="

# 1. Generate sequence-based release ID
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
    exit 1
fi

# 3. Create release directory and copy files
echo "Copying repository source to release directory..."
mkdir -p "$NEW_RELEASE_PATH"
cp -R "$TMP_SRC"/. "$NEW_RELEASE_PATH"/

# 4. Link shared assets
echo "Linking shared assets to current release..."
if [ -f "$SHARED_DIR/.env" ]; then
    ln -sf "$SHARED_DIR/.env" "$NEW_RELEASE_PATH/.env"
else
    echo "Warning: No shared .env file found in $SHARED_DIR. Deploying without linking .env."
fi

# 5. Run Compose Config Validation
echo "Validating Docker Compose configurations in release directory..."
cd "$NEW_RELEASE_PATH"
make config-check

# ------------------------------------------------------------------------------
# Blue-Green Deployment Logic
# ------------------------------------------------------------------------------
# Read current Traefik config to identify active target
TRAEFIK_DYNAMIC_FILE="$NEW_RELEASE_PATH/configs/traefik/dynamic.yml"

if [ ! -f "$TRAEFIK_DYNAMIC_FILE" ]; then
    echo "ERROR: Traefik dynamic configuration file not found at $TRAEFIK_DYNAMIC_FILE."
    exit 1
fi

echo "Checking currently active routing target..."
if grep -q "neos-app-blue" "$TRAEFIK_DYNAMIC_FILE"; then
    ACTIVE_COLOR="blue"
    INACTIVE_COLOR="green"
elif grep -q "neos-app-green" "$TRAEFIK_DYNAMIC_FILE"; then
    ACTIVE_COLOR="green"
    INACTIVE_COLOR="blue"
else
    # Fallback default
    ACTIVE_COLOR="green"
    INACTIVE_COLOR="blue"
fi

echo "  Active Color   : $ACTIVE_COLOR"
echo "  Deploying To   : $INACTIVE_COLOR (Inactive target)"

# 6. Database Migrations (Supabase Compatible Schema check)
echo "--- Running Database Migrations (Supabase schema-ready) ---"
# Placeholder database migrations trigger:
# docker compose exec -T db psql -U postgres -d neos_app -f migrations.sql || true

# 7. Spin up the inactive container
echo "Starting container: neos-app-$INACTIVE_COLOR..."
docker compose --profile apps up -d --build "neos-app-$INACTIVE_COLOR"

# 8. Post-Startup Healthcheck Probe
echo "Running health checks on the new $INACTIVE_COLOR container..."
HEALTHY=0
for i in {1..12}; do
    # Run a temporary curl checker inside the private app network
    if docker run --rm --network neos-private alpine curl -s -f "http://neos-app-$INACTIVE_COLOR:80/" &>/dev/null; then
        echo "  [PASS] Container http://neos-app-$INACTIVE_COLOR is healthy!"
        HEALTHY=1
        break
    fi
    echo "  Container not ready yet (attempt $i/12), waiting 5s..."
    sleep 5
done

# 9. Evaluate health status
if [ "$HEALTHY" -eq 1 ]; then
    echo "--- Swap Traffic (Zero-Downtime Swap) ---"
    # Modify Traefik dynamic file to swap targets
    # Update target routing link inside dynamic.yml
    sed -i "s/neos-app-$ACTIVE_COLOR/neos-app-$INACTIVE_COLOR/g" "$TRAEFIK_DYNAMIC_FILE"
    
    # Sync dynamic file to shared volume config so Traefik picks it up instantly
    if [ -f "/srv/neos/current/configs/traefik/dynamic.yml" ]; then
        # Swap on shared active dynamic config as well
        sed -i "s/neos-app-$ACTIVE_COLOR/neos-app-$INACTIVE_COLOR/g" "/srv/neos/current/configs/traefik/dynamic.yml"
    fi
    
    # Atomic symlink swap
    echo "Performing atomic symlink swap..."
    ln -sfn "$NEW_RELEASE_PATH" "$BASE_DIR/current_tmp"
    mv -Tf "$BASE_DIR/current_tmp" "$CURRENT_LINK"
    echo "Active release switched: $CURRENT_LINK -> $(readlink $CURRENT_LINK)"

    # Stop the old container to reclaim VPS memory resources
    echo "Stopping old active container: neos-app-$ACTIVE_COLOR..."
    docker compose stop "neos-app-$ACTIVE_COLOR" || true

    # Clean up staging folder
    echo "Cleaning staging directory..."
    rm -rf "$TMP_SRC"/*

    # Prune old releases (retain latest 5)
    echo "Pruning older releases (retaining latest 5)..."
    cd "$RELEASES_DIR"
    ls -1t | tail -n +6 | while read -r old_release; do
        if [ -n "$old_release" ]; then
            echo "Removing obsolete release: $old_release"
            rm -rf "$old_release"
        fi
    done
    
    echo "=========================================================================="
    echo "=== [SUCCESS] Release $RELEASE_ID Successfully Swapped and Active! ==="
    echo "=========================================================================="
else
    echo "=========================================================================="
    echo ">>> [FAILURE] Healthcheck failed. Triggering AUTOMATIC ROLLBACK..."
    echo "=========================================================================="
    # Stop and remove the unhealthy container
    docker compose stop "neos-app-$INACTIVE_COLOR" || true
    docker compose rm -f "neos-app-$INACTIVE_COLOR" || true
    
    # Revert any code staging modifications
    rm -rf "$NEW_RELEASE_PATH"
    
    echo "Automatic rollback finished. Active production traffic remained on $ACTIVE_COLOR."
    exit 1
fi
