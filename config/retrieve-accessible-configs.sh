#!/bin/bash

#
# retrieve-accessible-configs.sh - Retrieve accessible configuration files
# Retrieves files that don't require sudo access
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="${SCRIPT_DIR}/accessible-configs-${BACKUP_TIMESTAMP}"

# Configuration
REMOTE_SERVER="${1:-jxqz.org}"
REMOTE_USER="${REMOTE_USER:-steve}"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

# Test SSH connectivity
log "Testing SSH connectivity to ${REMOTE_USER}@${REMOTE_SERVER}..."
if ! ssh -o ConnectTimeout=10 -o BatchMode=yes "${REMOTE_USER}@${REMOTE_SERVER}" 'echo "SSH connection successful"' 2>/dev/null; then
    echo "Error: Cannot connect to ${REMOTE_USER}@${REMOTE_SERVER}"
    exit 1
fi

# Create backup directory
mkdir -p "$BACKUP_DIR"

log "Starting accessible configuration retrieval from ${REMOTE_USER}@${REMOTE_SERVER}..."

# Get readable system information
log "Gathering system information..."
ssh "${REMOTE_USER}@${REMOTE_SERVER}" "
    echo '=== System Information ===' > /tmp/accessible_info.txt
    echo 'Date: \$(date)' >> /tmp/accessible_info.txt
    echo 'Hostname: \$(hostname)' >> /tmp/accessible_info.txt
    echo 'User: \$(whoami)' >> /tmp/accessible_info.txt
    echo 'Home: \$HOME' >> /tmp/accessible_info.txt
    echo 'OS: \$(cat /etc/os-release 2>/dev/null | grep PRETTY_NAME || echo \"Unknown\")' >> /tmp/accessible_info.txt
    echo 'Kernel: \$(uname -r)' >> /tmp/accessible_info.txt
    echo '' >> /tmp/accessible_info.txt
    
    echo '=== What user can see in /etc ===' >> /tmp/accessible_info.txt
    ls -la /etc/ 2>/dev/null | head -20 >> /tmp/accessible_info.txt || echo 'Cannot list /etc' >> /tmp/accessible_info.txt
    echo '' >> /tmp/accessible_info.txt
    
    echo '=== Apache-related processes ===' >> /tmp/accessible_info.txt
    ps aux | grep apache2 | grep -v grep >> /tmp/accessible_info.txt || echo 'No apache processes visible' >> /tmp/accessible_info.txt
    echo '' >> /tmp/accessible_info.txt
    
    echo '=== Apache binaries ===' >> /tmp/accessible_info.txt
    which apache2 >> /tmp/accessible_info.txt 2>/dev/null || echo 'apache2 not in PATH'
    which apache2ctl >> /tmp/accessible_info.txt 2>/dev/null || echo 'apache2ctl not in PATH'
    echo '' >> /tmp/accessible_info.txt
    
    echo '=== Web directories user can see ===' >> /tmp/accessible_info.txt
    ls -la /var/www/ 2>/dev/null >> /tmp/accessible_info.txt || echo 'Cannot access /var/www'
    echo '' >> /tmp/accessible_info.txt
    
    echo '=== User home directory ===' >> /tmp/accessible_info.txt
    ls -la \$HOME/ >> /tmp/accessible_info.txt
    echo '' >> /tmp/accessible_info.txt
    
    echo '=== Web-related files in home ===' >> /tmp/accessible_info.txt
    find \$HOME -name '*.conf' -o -name '*.cfg' -o -name '*.html' 2>/dev/null | head -10 >> /tmp/accessible_info.txt
    echo '' >> /tmp/accessible_info.txt
    
    echo '=== Cron jobs for user ===' >> /tmp/accessible_info.txt
    crontab -l >> /tmp/accessible_info.txt 2>/dev/null || echo 'No user crontab'
    echo '' >> /tmp/accessible_info.txt
    
    echo '=== Sudo capabilities ===' >> /tmp/accessible_info.txt
    sudo -l >> /tmp/accessible_info.txt 2>/dev/null || echo 'Cannot check sudo capabilities (may require password)'
"

# Retrieve the information
scp "${REMOTE_USER}@${REMOTE_SERVER}:/tmp/accessible_info.txt" "$BACKUP_DIR/ACCESSIBLE_INFO.txt" 2>/dev/null
ssh "${REMOTE_USER}@${REMOTE_SERVER}" "rm -f /tmp/accessible_info.txt"

# Copy user-accessible files
log "Retrieving user configuration files..."
rsync -avz "${REMOTE_USER}@${REMOTE_SERVER}:.bashrc" "$BACKUP_DIR/" 2>/dev/null || true
rsync -avz "${REMOTE_USER}@${REMOTE_SERVER}:.bash_profile" "$BACKUP_DIR/" 2>/dev/null || true
rsync -avz "${REMOTE_USER}@${REMOTE_SERVER}:.vimrc" "$BACKUP_DIR/" 2>/dev/null || true
rsync -avz "${REMOTE_USER}@${REMOTE_SERVER}:.profile" "$BACKUP_DIR/" 2>/dev/null || true
rsync -avz "${REMOTE_USER}@${REMOTE_SERVER}:.ssh/config" "$BACKUP_DIR/" 2>/dev/null || true

# Copy any scripts or tools
rsync -avz "${REMOTE_USER}@${REMOTE_SERVER}:bin/" "$BACKUP_DIR/bin/" 2>/dev/null || true
rsync -avz "${REMOTE_USER}@${REMOTE_SERVER}:scripts/" "$BACKUP_DIR/scripts/" 2>/dev/null || true

# Copy any web content
rsync -avz "${REMOTE_USER}@${REMOTE_SERVER}:public_html/" "$BACKUP_DIR/public_html/" 2>/dev/null || true
rsync -avz "${REMOTE_USER}@${REMOTE_SERVER}:www/" "$BACKUP_DIR/www/" 2>/dev/null || true

log "✅ Accessible configuration retrieval completed!"
log "📁 Location: $BACKUP_DIR"
log "📄 System info: $BACKUP_DIR/ACCESSIBLE_INFO.txt"
log ""
log "To get system configurations that require sudo, you can run:"
log "ssh ${REMOTE_USER}@${REMOTE_SERVER}"
log "sudo cp -r /etc/apache2 /tmp/apache2_backup"
log "sudo chown -R ${REMOTE_USER}:${REMOTE_USER} /tmp/apache2_backup"
log "exit"
log "rsync -avz ${REMOTE_USER}@${REMOTE_SERVER}:/tmp/apache2_backup/ ./apache2/"