#!/bin/bash
# ==============================================================================
# NEOS PLATFORM - SHARED INFRASTRUCTURE DEPLOYMENT SCRIPT
# ==============================================================================
# Use this script to deploy or update the shared infrastructure.
# Usage: ./deploy.sh

set -e
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$REPO_DIR/.env"

# 1. Check if .env file exists
if [ ! -f "$ENV_FILE" ]; then
    echo "Error: .env file not found at $ENV_FILE."
    echo "Please copy .env.example to .env and configure your variables before deploying."
    exit 1
fi

echo "=== Deploying Neos Platform Infrastructure ==="

# 2. Verify Docker daemon is running
if ! docker info &> /dev/null; then
    echo "Error: Docker is not running. Please start Docker first."
    exit 1
fi

# 3. Validate Docker Compose config
echo "Validating Docker Compose configuration..."
docker compose config > /dev/null
echo "Compose configuration is valid."

# 4. Pull and build services
echo "Pulling latest images and building custom containers..."
docker compose build --pull

# 5. Bring up services in background
echo "Starting services in detached mode..."
docker compose up -d --remove-orphans

# 6. Monitor startup and report container status
echo "--- Checking Service Statuses ---"
sleep 3
docker compose ps

echo "--- Checking Container Health Statuses ---"
docker compose ps --format "table {{.Name}}\t{{.Status}}"

echo "=========================================="
echo "Deployment completed!"
echo "Check Nginx logs for traffic: docker compose logs -f reverse-proxy"
echo "Check Postgres status: docker compose logs db"
echo "=========================================="
