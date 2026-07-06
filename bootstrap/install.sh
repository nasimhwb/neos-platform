#!/bin/bash
# ==============================================================================
# NEOS PLATFORM BOOTSTRAP - MASTER ARCHITECT INSTALLER
# ==============================================================================
# Run this script as root to bootstrap a clean Ubuntu 24.04 VPS:
#   sudo ./install.sh

set -e
set -o pipefail

# Ensure script is executed from its parent folder
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=========================================================================="
echo "         NEOS PLATFORM PRIVATE CLOUD FOUNDATION INITIALIZER v2            "
echo "=========================================================================="

# 1. Pre-flight Resource Validation
chmod +x verify.sh
./verify.sh

# 2. Check for .env file
REPO_DIR="$(dirname "$SCRIPT_DIR")"
if [ ! -f "$REPO_DIR/.env" ]; then
    echo "Warning: .env configuration file not found at repository root."
    if [ -f "$REPO_DIR/.env.example" ]; then
        echo "Creating default .env from .env.example..."
        cp "$REPO_DIR/.env.example" "$REPO_DIR/.env"
        echo "Default .env created. Please configure secrets inside it."
    else
        echo "Error: .env.example is missing. Cannot continue."
        exit 1
    fi
fi

# 3. Make all runner scripts executable
chmod +x ubuntu.sh docker.sh directories.sh security.sh

# 4. Provision Host Package Management
./ubuntu.sh

# 5. Provision Container Engines (Docker)
./docker.sh

# 6. Initialize Storage Volumes and Folders
./directories.sh

# 7. Configure Host Firewalls and SSL Bootstrapping
./security.sh

echo "=========================================================================="
echo "  Bootstrap installer successfully completed!                             "
echo "                                                                          "
echo "  Next Steps:                                                             "
echo "  1. Review and configure the credentials: nano $REPO_DIR/.env            "
echo "  2. Deploy the core stack: make up                                       "
echo "  3. Validate logs and health states: make ps                             "
echo "=========================================================================="
