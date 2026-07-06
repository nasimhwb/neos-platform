#!/bin/bash
# ==============================================================================
# NEOS PLATFORM BOOTSTRAP - MASTER RUNNER v3
# ==============================================================================
# Execute this script as root once to provision a new Hostinger VPS node.
# Usage: sudo ./install.sh

set -e
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=========================================================================="
echo "         NEOS PLATFORM PRIVATE CLOUD INITIALIZER v3 - STARTING             "
echo "=========================================================================="

# 1. Resource capacity checks (Fail Fast)
chmod +x verify.sh
./verify.sh

# 2. Check for .env file at repository root
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

# 3. Enable execution permissions on all scripts
chmod +x ubuntu.sh docker.sh security.sh directories.sh

# 4. Provision Host Package Management
./ubuntu.sh

# 5. Provision Container Engines (Docker)
./docker.sh

# 6. Provision Security and create 'nasim' user
./security.sh

# 7. Initialize Storage Volumes and Folders with 'nasim' ownership
./directories.sh

echo "=========================================================================="
echo "  Bootstrap setup successfully completed!                             "
echo "                                                                          "
echo "  Deployment Environment Configured:                                      "
echo "  - deployment user 'nasim' created and added to the docker/sudo groups.  "
echo "  - directories mapped under /srv/neos/ releases structure.               "
echo "                                                                          "
echo "  Next Steps:                                                             "
echo "  1. Add nasim's SSH public keys to /home/nasim/.ssh/authorized_keys      "
echo "  2. Review and configure credentials in /srv/neos/shared/.env            "
echo "  3. Deploy the core stack: make up                                       "
echo "=========================================================================="
