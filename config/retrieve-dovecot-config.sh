#!/bin/bash

#
# retrieve-dovecot-config.sh - Get Dovecot mail server configuration
# Requires sudo access on the remote server
#

set -euo pipefail

REMOTE_SERVER="${1:-jxqz.org}"
REMOTE_USER="${REMOTE_USER:-steve}"
BACKUP_DIR="./dovecot-config-$(date +%Y%m%d-%H%M%S)"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

echo "Getting Dovecot configuration from ${REMOTE_USER}@${REMOTE_SERVER}..."
echo "This will require sudo password on the remote server."
echo ""

# Test SSH connectivity
if ! ssh -o ConnectTimeout=10 "${REMOTE_USER}@${REMOTE_SERVER}" 'echo "SSH connection successful"' 2>/dev/null; then
    echo "Error: Cannot connect to ${REMOTE_USER}@${REMOTE_SERVER}"
    exit 1
fi

# Create backup directory
mkdir -p "$BACKUP_DIR"

log "Attempting to retrieve Dovecot configuration..."

# Method 1: Try to get dovecot config with interactive sudo
ssh -t "${REMOTE_USER}@${REMOTE_SERVER}" "
    echo 'Creating temporary Dovecot backup...'
    sudo cp -r /etc/dovecot /tmp/dovecot_backup_\$\$ 2>/dev/null || { echo 'Failed to copy dovecot config'; exit 1; }
    sudo chown -R ${REMOTE_USER}:${REMOTE_USER} /tmp/dovecot_backup_\$\$
    echo 'Dovecot config copied to /tmp/dovecot_backup_\$\$'
    echo 'Use: rsync -avz ${REMOTE_USER}@${REMOTE_SERVER}:/tmp/dovecot_backup_\$\$/ ./dovecot-config/'
    echo 'Then: ssh ${REMOTE_USER}@${REMOTE_SERVER} \"rm -rf /tmp/dovecot_backup_\$\$\"'
"

echo ""
echo "If the above worked, you can now run:"
echo "  rsync -avz ${REMOTE_USER}@${REMOTE_SERVER}:/tmp/dovecot_backup_*/ $BACKUP_DIR/"
echo "  ssh ${REMOTE_USER}@${REMOTE_SERVER} 'rm -rf /tmp/dovecot_backup_*'"
echo ""
echo "This will safely retrieve your Dovecot configuration without filling up server space."