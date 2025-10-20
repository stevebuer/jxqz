#!/bin/bash

#
# backup-apache-config.sh - Apache2 Configuration Backup Script
# Part of JXQZ disaster recovery toolkit
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="${SCRIPT_DIR}/apache2-backup-$(date +%Y%m%d-%H%M%S)"

echo "Starting Apache2 configuration backup..."

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Check if running as root/sudo
if [[ $EUID -ne 0 ]]; then
    echo "This script needs sudo access to read Apache configuration files."
    echo "Please run with sudo or as root."
    exit 1
fi

# Backup main Apache configuration
echo "Backing up Apache2 configuration..."
cp -r /etc/apache2/* "$BACKUP_DIR/" 2>/dev/null || {
    echo "Error: Could not access /etc/apache2/"
    echo "Make sure Apache2 is installed and you have proper permissions."
    exit 1
}

# Remove sensitive files that shouldn't be in version control
echo "Removing sensitive files..."
if [[ -d "$BACKUP_DIR/ssl/private" ]]; then
    rm -rf "$BACKUP_DIR/ssl/private"
fi

# Remove private keys from any location
find "$BACKUP_DIR" -name "*.key" -delete 2>/dev/null || true
find "$BACKUP_DIR" -name "*private*" -type f -delete 2>/dev/null || true

# Create a manifest of what was backed up
echo "Creating backup manifest..."
cat > "$BACKUP_DIR/BACKUP_MANIFEST.txt" << EOF
Apache2 Configuration Backup
Generated: $(date)
Hostname: $(hostname)
Apache Version: $(apache2 -v 2>/dev/null | head -1 || echo "Unknown")

Files backed up:
$(find "$BACKUP_DIR" -type f | sort)

Excluded for security:
- SSL private keys (*.key files)
- Files in ssl/private/ directory
- Any files containing 'private' in the name

Recovery: See config/README.md for restoration instructions
EOF

# Set proper ownership (back to original user if run with sudo)
if [[ -n "${SUDO_USER:-}" ]]; then
    chown -R "${SUDO_USER}:${SUDO_USER}" "$BACKUP_DIR"
fi

echo ""
echo "✅ Apache configuration backed up successfully!"
echo "📁 Location: $BACKUP_DIR"
echo "📋 Manifest: $BACKUP_DIR/BACKUP_MANIFEST.txt"
echo ""
echo "⚠️  Remember to:"
echo "   - Backup SSL certificates separately"
echo "   - Test the backup by reviewing sensitive file removal"
echo "   - Store this backup in your disaster recovery location"
echo ""
echo "🔄 Add to git and push to remote repository for safekeeping:"
echo "   git add config/"
echo "   git commit -m \"Update Apache configuration backup\""
echo "   git push"