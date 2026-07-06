#!/bin/bash
# ==============================================================================
# NEOS PLATFORM SECURITY - FIREWALL AND BAN POLICY
# ==============================================================================
# This script applies additional Host security settings (UFW, Fail2ban).

set -e

echo "Applying production UFW firewall policies..."

# Reset UFW rules
ufw --force reset

# Set default policies
ufw default deny incoming
ufw default allow outgoing

# Allow SSH, HTTP, HTTPS
ufw allow 22/tcp comment 'SSH Port'
ufw allow 80/tcp comment 'HTTP Web Port'
ufw allow 443/tcp comment 'HTTPS Secure Web Port'

# Enable UFW
ufw --force enable
ufw status verbose

echo "UFW Firewall successfully applied."
echo "Placeholder: Configure Fail2ban jail for SSH and Nginx logins under /etc/fail2ban/jail.local"
