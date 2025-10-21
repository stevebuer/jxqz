#!/bin/bash

#
# backup-to-sd.sh - Backup production mirror to SD card
#
# This creates a complete backup of your production mirror on the SD card
# for safe, portable, off-system storage.

set -euo pipefail

# Configuration
SOURCE="/var/www/production-mirror/current"
SD_CARD="/media/steve/STORAGE"
BACKUP_DIR="$SD_CARD/JXQZ_PRODUCTION_BACKUP"
DATE_STAMP=$(date '+%Y-%m-%d_%H-%M-%S')
BACKUP_PATH="$BACKUP_DIR/$DATE_STAMP"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $*"
}

success() {
    echo -e "${GREEN}✅${NC} $*"
}

warning() {
    echo -e "${YELLOW}⚠️${NC} $*"
}

error() {
    echo -e "${RED}❌${NC} $*"
}

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    # Check if source exists
    if [[ ! -d "$SOURCE" ]]; then
        error "Production mirror not found at: $SOURCE"
        exit 1
    fi
    
    # Check if SD card is mounted
    if [[ ! -d "$SD_CARD" ]]; then
        error "SD card not mounted at: $SD_CARD"
        exit 1
    fi
    
    # Check available space
    local source_size=$(du -sb "$SOURCE" | cut -f1)
    local avail_space=$(df --output=avail "$SD_CARD" | tail -1)
    local avail_bytes=$((avail_space * 1024))
    
    local source_gb=$((source_size / 1024 / 1024 / 1024))
    local avail_gb=$((avail_bytes / 1024 / 1024 / 1024))
    
    log "Source size: ${source_gb}GB"
    log "Available space: ${avail_gb}GB"
    
    if [[ $source_size -gt $avail_bytes ]]; then
        error "Not enough space on SD card!"
        echo "Need: ${source_gb}GB, Available: ${avail_gb}GB"
        exit 1
    fi
    
    success "Prerequisites check passed"
}

# Create backup structure
create_backup_structure() {
    log "Creating backup structure..."
    
    mkdir -p "$BACKUP_PATH"
    
    # Create info file
    cat > "$BACKUP_PATH/BACKUP_INFO.md" << EOF
# JXQZ Production Backup

**Created**: $(date)
**Source**: $SOURCE
**Original Server**: jxqz.org
**Backup Size**: $(du -sh "$SOURCE" | cut -f1)

## Contents
- \`web-content/\` - Complete website files
- \`config/\` - Server configuration files
- \`logs/\` - Selected log files

## Excluded
- \`databases/\` - Skipped (school/hobby project data, not critical)

## Restore Instructions
To restore this backup:
1. Extract to desired location
2. Set up web server pointing to web-content/
3. Adapt configuration files for new environment

## Notes
- This is a complete mirror of production web content as of backup date
- Safe to use for development, testing, or disaster recovery
- Databases excluded as they contain non-critical school/hobby project data
- Original source: /var/www/production-mirror/current
EOF

    success "Backup structure created"
}

# Perform the backup
perform_backup() {
    log "Starting backup to SD card..."
    log "Source: $SOURCE"
    log "Destination: $BACKUP_PATH"
    
    # Use rsync for efficient, resumable backup
    # Exclude databases directory (school/hobby project data not critical)
    rsync -av --progress --stats \
        --exclude='databases/' \
        "$SOURCE/" \
        "$BACKUP_PATH/" || {
        warning "Backup may have been interrupted"
        echo "You can resume by running this script again"
        return 1
    }
    
    log "Skipped databases/ directory (school/hobby project data)"
    success "Backup completed successfully"
}

# Create easy access symlink
create_current_link() {
    log "Creating 'latest' symlink..."
    
    local latest_link="$BACKUP_DIR/latest"
    
    # Remove old link if exists
    [[ -L "$latest_link" ]] && rm "$latest_link"
    
    # Create new symlink
    ln -sf "$BACKUP_PATH" "$latest_link"
    
    success "Latest backup linked at: $latest_link"
}

# Generate backup summary
generate_summary() {
    log "Generating backup summary..."
    
    local total_files=$(find "$BACKUP_PATH" -type f | wc -l)
    local total_size=$(du -sh "$BACKUP_PATH" | cut -f1)
    
    cat > "$BACKUP_DIR/BACKUP_SUMMARY.md" << EOF
# JXQZ Production Backup Summary

## Latest Backup
**Date**: $(date)
**Location**: $BACKUP_PATH
**Size**: $total_size
**Files**: $total_files

## All Backups
EOF
    
    # List all backups
    find "$BACKUP_DIR" -maxdepth 1 -type d -name "20*" | sort -r | while read backup; do
        local backup_name=$(basename "$backup")
        local backup_size=$(du -sh "$backup" 2>/dev/null | cut -f1 || echo "Unknown")
        echo "- **$backup_name**: $backup_size" >> "$BACKUP_DIR/BACKUP_SUMMARY.md"
    done
    
    cat >> "$BACKUP_DIR/BACKUP_SUMMARY.md" << EOF

## SD Card Status
$(df -h "$SD_CARD")

## Quick Access
- **Latest backup**: \`$BACKUP_DIR/latest/\`
- **Web content**: \`$BACKUP_DIR/latest/web-content/\`
- **Config files**: \`$BACKUP_DIR/latest/config/\`

## Restore Command Examples
\`\`\`bash
# Copy web content to new server
rsync -av $BACKUP_DIR/latest/web-content/ /var/www/html/

# Copy config files
rsync -av $BACKUP_DIR/latest/config/ /etc/apache2/sites-available/

# View backup info
cat $BACKUP_DIR/latest/BACKUP_INFO.md
\`\`\`
EOF

    success "Backup summary: $BACKUP_DIR/BACKUP_SUMMARY.md"
}

# Main execution
main() {
    echo "💾 JXQZ Production Backup to SD Card"
    echo "===================================="
    echo ""
    
    check_prerequisites
    create_backup_structure  
    perform_backup
    create_current_link
    generate_summary
    
    echo ""
    success "SD card backup completed successfully!"
    echo ""
    echo "📁 Backup location: $BACKUP_PATH"
    echo "🔗 Latest link: $BACKUP_DIR/latest"
    echo "📊 Summary: $BACKUP_DIR/BACKUP_SUMMARY.md"
    echo ""
    echo "💾 SD card usage:"
    df -h "$SD_CARD"
    echo ""
    echo "🎯 Your production content is now safely backed up to portable storage!"
}

main "$@"