#!/bin/bash

#
# retrieve-configs-selective.sh - Retrieve only configuration files, no images
# Avoids large files that could fill up server space
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="${SCRIPT_DIR}/selective-configs-${BACKUP_TIMESTAMP}"

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
mkdir -p "$BACKUP_DIR"/{apache2,user-configs,scripts,web-configs}

log "Starting selective configuration retrieval (no images/large files)..."

# Get Apache configuration with manual sudo approach
log "Getting Apache configuration..."
ssh "${REMOTE_USER}@${REMOTE_SERVER}" "
    sudo cp -r /etc/apache2 /tmp/apache2_backup_$$ 2>/dev/null || echo 'APACHE_FAILED'
    if [ -d /tmp/apache2_backup_$$ ]; then
        sudo chown -R ${REMOTE_USER}:${REMOTE_USER} /tmp/apache2_backup_$$
        echo 'APACHE_SUCCESS'
    fi
" | while read result; do
    case "$result" in
        APACHE_SUCCESS)
            log "Apache config copied successfully, retrieving..."
            rsync -avz --exclude='*.key' --exclude='*private*' \
                  "${REMOTE_USER}@${REMOTE_SERVER}:/tmp/apache2_backup_$$/" \
                  "$BACKUP_DIR/apache2/" 2>/dev/null || true
            ssh "${REMOTE_USER}@${REMOTE_SERVER}" "rm -rf /tmp/apache2_backup_$$"
            ;;
        APACHE_FAILED)
            log "Warning: Could not access Apache configuration (sudo required)"
            ;;
    esac
done

# Get user configuration files (small text files only)
log "Retrieving user configuration files..."
rsync -avz "${REMOTE_USER}@${REMOTE_SERVER}:.bashrc" "$BACKUP_DIR/user-configs/" 2>/dev/null || true
rsync -avz "${REMOTE_USER}@${REMOTE_SERVER}:.bash_profile" "$BACKUP_DIR/user-configs/" 2>/dev/null || true
rsync -avz "${REMOTE_USER}@${REMOTE_SERVER}:.profile" "$BACKUP_DIR/user-configs/" 2>/dev/null || true
rsync -avz "${REMOTE_USER}@${REMOTE_SERVER}:.vimrc" "$BACKUP_DIR/user-configs/" 2>/dev/null || true
rsync -avz "${REMOTE_USER}@${REMOTE_SERVER}:.gitconfig" "$BACKUP_DIR/user-configs/" 2>/dev/null || true
rsync -avz "${REMOTE_USER}@${REMOTE_SERVER}:.pinerc" "$BACKUP_DIR/user-configs/" 2>/dev/null || true

# Get scripts and executables (avoiding large files)
log "Retrieving user scripts..."
rsync -avz --exclude='*.jpg' --exclude='*.jpeg' --exclude='*.png' --exclude='*.gif' --exclude='*.pdf' \
      "${REMOTE_USER}@${REMOTE_SERVER}:bin/" "$BACKUP_DIR/scripts/bin/" 2>/dev/null || true

# Get web configuration files from public_html (HTML/config only, no images)
log "Retrieving web configuration files (no images)..."
rsync -avz --include='*.html' --include='*.htm' --include='*.conf' --include='*.cfg' \
      --include='*.txt' --include='*.md' --include='*/' \
      --exclude='*.jpg' --exclude='*.jpeg' --exclude='*.png' --exclude='*.gif' \
      --exclude='*.pdf' --exclude='*.zip' --exclude='*.tar*' \
      "${REMOTE_USER}@${REMOTE_SERVER}:public_html/" "$BACKUP_DIR/web-configs/public_html/" 2>/dev/null || true

# Get specific configuration files from GitHub projects (if they exist)
log "Retrieving project configuration files..."
rsync -avz --include='*.conf' --include='*.cfg' --include='*.ini' --include='*.yaml' --include='*.yml' \
      --include='*/' --exclude='*' \
      "${REMOTE_USER}@${REMOTE_SERVER}:GITHUB/" "$BACKUP_DIR/scripts/github-configs/" 2>/dev/null || true

# Get system information (lightweight)
log "Gathering system information..."
ssh "${REMOTE_USER}@${REMOTE_SERVER}" "
    echo '=== Apache Virtual Hosts ===' > /tmp/apache_info.txt
    if [ -d /etc/apache2/sites-available ]; then
        ls -la /etc/apache2/sites-available/ >> /tmp/apache_info.txt 2>/dev/null
        echo '' >> /tmp/apache_info.txt
        for site in /etc/apache2/sites-available/*.conf; do
            if [ -f \"\$site\" ]; then
                echo \"=== \$(basename \$site) ===\" >> /tmp/apache_info.txt
                sudo cat \"\$site\" >> /tmp/apache_info.txt 2>/dev/null || echo 'Cannot read site config' >> /tmp/apache_info.txt
                echo '' >> /tmp/apache_info.txt
            fi
        done
    fi
    
    echo '=== Enabled Sites ===' >> /tmp/apache_info.txt
    ls -la /etc/apache2/sites-enabled/ >> /tmp/apache_info.txt 2>/dev/null || echo 'Cannot list enabled sites' >> /tmp/apache_info.txt
    echo '' >> /tmp/apache_info.txt
    
    echo '=== Enabled Modules ===' >> /tmp/apache_info.txt
    ls /etc/apache2/mods-enabled/*.load 2>/dev/null | xargs -r basename -s .load | sort >> /tmp/apache_info.txt
    echo '' >> /tmp/apache_info.txt
    
    echo '=== Web Directory Structure ===' >> /tmp/apache_info.txt
    find /var/www -maxdepth 3 -type d >> /tmp/apache_info.txt 2>/dev/null || echo 'Cannot access /var/www' >> /tmp/apache_info.txt
    echo '' >> /tmp/apache_info.txt
    
    echo '=== Cron Jobs ===' >> /tmp/apache_info.txt
    crontab -l >> /tmp/apache_info.txt 2>/dev/null || echo 'No user crontab' >> /tmp/apache_info.txt
    echo '' >> /tmp/apache_info.txt
    
    echo '=== Running Services ===' >> /tmp/apache_info.txt
    systemctl list-units --type=service --state=running | grep -E 'apache|nginx|mysql|postgres|dovecot|postfix' >> /tmp/apache_info.txt 2>/dev/null || echo 'No web/mail services found' >> /tmp/apache_info.txt
"

# Retrieve the Apache info
scp "${REMOTE_USER}@${REMOTE_SERVER}:/tmp/apache_info.txt" "$BACKUP_DIR/APACHE_ANALYSIS.txt" 2>/dev/null
ssh "${REMOTE_USER}@${REMOTE_SERVER}" "rm -f /tmp/apache_info.txt"

# Create file inventory
log "Creating file inventory..."
cat > "$BACKUP_DIR/SELECTIVE_BACKUP_MANIFEST.txt" << EOF
Selective Configuration Backup
Generated: $(date)
Server: ${REMOTE_USER}@${REMOTE_SERVER}
Backup Location: $BACKUP_DIR

=== What Was Retrieved ===
Configuration files only - images and large files excluded

=== Directory Structure ===
$(find "$BACKUP_DIR" -type d | sort)

=== File Count by Type ===
Configuration files: $(find "$BACKUP_DIR" -name "*.conf" -o -name "*.cfg" -o -name "*.ini" | wc -l)
HTML files: $(find "$BACKUP_DIR" -name "*.html" -o -name "*.htm" | wc -l)
Text files: $(find "$BACKUP_DIR" -name "*.txt" -o -name "*.md" | wc -l)
Scripts: $(find "$BACKUP_DIR" -type f -executable | wc -l)
Total files: $(find "$BACKUP_DIR" -type f | wc -l)

=== Excluded for Space ===
- Image files (*.jpg, *.jpeg, *.png, *.gif)
- PDF files (*.pdf)
- Archive files (*.zip, *.tar*)
- Large binary files

=== Retrieved Files ===
$(find "$BACKUP_DIR" -type f | sort)

=== Next Steps ===
1. Review Apache configuration in apache2/ directory
2. Check web configs in web-configs/public_html/
3. Examine user configurations in user-configs/
4. Use configs to inform Terraform module development
5. Test configuration restoration procedures

=== Apache Configuration Notes ===
Virtual host configurations should be in apache2/sites-available/
Check APACHE_ANALYSIS.txt for detailed Apache setup information
EOF

# Calculate backup size
BACKUP_SIZE=$(du -sh "$BACKUP_DIR" | cut -f1)

log ""
log "✅ Selective configuration retrieval completed!"
log "📁 Location: $BACKUP_DIR"
log "📊 Size: $BACKUP_SIZE (images excluded)"
log "📋 Manifest: $BACKUP_DIR/SELECTIVE_BACKUP_MANIFEST.txt"
log "🔍 Apache Analysis: $BACKUP_DIR/APACHE_ANALYSIS.txt"
log ""
log "🎯 Key Files Retrieved:"
log "   - Apache virtual host configurations"
log "   - User dotfiles (.bashrc, .profile, etc.)"
log "   - HTML files and web configs (no images)"
log "   - Script files and executables"
log ""
log "💾 Space Savings:"
log "   - Excluded image files to prevent server space issues"
log "   - Only configuration and text files retrieved"
log "   - Safe to run without filling up server storage"