#!/bin/bash

#
# setup-var-www-permissions.sh - Set up /var/www for production mirror
#

set -euo pipefail

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $*"
}

success() {
    echo -e "${GREEN}✅${NC} $*"
}

log "Setting up /var/www permissions for production mirror..."

# Create production-mirror directory with proper permissions
sudo mkdir -p /var/www/production-mirror
sudo chown "$USER:$USER" /var/www/production-mirror
sudo chmod 755 /var/www/production-mirror

# Show current setup
echo ""
log "Current /var/www structure:"
ls -la /var/www/

echo ""
log "Available space:"
df -h /var

success "/var/www/production-mirror ready for use"
echo "You can now run: ./mirror-production-to-var.sh your-server-address"