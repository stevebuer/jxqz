#!/bin/bash

#
# mirror-production-to-var.sh - Mirror production web content to /var/www
#
# This script mirrors production content to /var/www/production-mirror
# which can later be moved to a dedicated storage mount point.
#

set -euo pipefail

# Configuration
PROD_SERVER="your-server-ip-or-domain"
PROD_USER="steve"
LOCAL_MIRROR_BASE="/var/www/production-mirror"
DATE_STAMP=$(date '+%Y-%m-%d_%H-%M-%S')
MIRROR_DIR="$LOCAL_MIRROR_BASE/$DATE_STAMP"
CURRENT_LINK="$LOCAL_MIRROR_BASE/current"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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
    
    # Check if running as root or with sudo for /var/www access
    if [[ ! -w /var/www ]]; then
        error "Cannot write to /var/www. Please run with sudo or fix permissions."
        echo "Try: sudo chown $USER:$USER /var/www"
        echo "Or run: sudo $0 $*"
        exit 1
    fi
    
    # Check available space
    local avail_space=$(df /var --output=avail | tail -1)
    local avail_gb=$((avail_space / 1024 / 1024))
    
    log "Available space in /var: ${avail_gb}GB"
    
    if [[ $avail_gb -lt 5 ]]; then
        error "Less than 5GB available in /var. May not be enough for production mirror."
        echo "Current space: ${avail_gb}GB"
        echo "Consider cleaning up or using a different location."
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    success "Prerequisites check passed (${avail_gb}GB available)"
}

# Create mirror directory structure
create_mirror_structure() {
    log "Creating mirror directory structure in /var/www..."
    
    sudo mkdir -p "$MIRROR_DIR"/{web-content,databases,config,logs}
    sudo chown -R "$USER:$USER" "$MIRROR_DIR"
    
    cat > "$MIRROR_DIR/README.md" << EOF
# Production Mirror - $(date)

**Server**: $PROD_SERVER  
**User**: $PROD_USER  
**Local Path**: $MIRROR_DIR  
**Purpose**: Backup and development environment

## Contents
- \`web-content/\` - All website files from production
- \`databases/\` - Database backups (SQL files)  
- \`config/\` - Server configuration files
- \`logs/\` - Selected log files

## Usage
This mirror can be:
1. Served directly by Apache (development)
2. Used as backup restoration source
3. Moved to dedicated storage later
4. Used for local development setup

## Future Storage Migration
When ready, this entire directory can be moved to dedicated storage:
\`\`\`bash
# Example: Move to dedicated SSD mount
sudo rsync -av $MIRROR_DIR/ /mnt/storage/production-mirror/
sudo ln -sfn /mnt/storage/production-mirror /var/www/production-mirror
\`\`\`
EOF

    success "Mirror structure created"
}

# Mirror web content with size estimation
mirror_web_content() {
    log "Mirroring web content..."
    
    # First, get size estimate
    log "Estimating production content size..."
    local est_size=$(ssh "$PROD_USER@$PROD_SERVER" "
        du -sh /var/www 2>/dev/null | cut -f1 || echo 'Unknown'
        echo -n ' + '
        du -sh ~/public_html 2>/dev/null | cut -f1 || echo '0'
    " 2>/dev/null || echo "Size estimation failed")
    
    log "Estimated production size: $est_size"
    
    # Apache DocumentRoot and sites
    log "Syncing /var/www/..."
    rsync -avz --progress --stats \
        "$PROD_USER@$PROD_SERVER:/var/www/" \
        "$MIRROR_DIR/web-content/var-www/" \
        --exclude="*.log" \
        --exclude="cache/*" \
        --exclude="tmp/*" \
        --exclude="sessions/*" || warning "Some files in /var/www may not be accessible"
    
    # User home directory web content
    log "Syncing user web directories..."
    rsync -avz --progress --stats \
        "$PROD_USER@$PROD_SERVER:~/" \
        "$MIRROR_DIR/web-content/home-steve/" \
        --include="public_html/***" \
        --include="www/***" \
        --include="Sites/***" \
        --include="*.html" \
        --include="*.php" \
        --include="*.css" \
        --include="*.js" \
        --include="*.md" \
        --include="*.txt" \
        --exclude="*" || warning "Some user files may not be accessible"
    
    success "Web content mirrored"
}

# Quick backup databases
mirror_databases() {
    log "Creating database backups..."
    
    # PostgreSQL databases - lightweight approach
    log "Backing up PostgreSQL databases..."
    ssh "$PROD_USER@$PROD_SERVER" "
        mkdir -p ~/temp_db_backup
        # List and backup databases
        sudo -u postgres psql -l -t | cut -d'|' -f1 | sed 's/^ *//g' | grep -v '^$' | grep -v 'template' | grep -v 'postgres' | while read db; do
            if [[ -n \"\$db\" && \"\$db\" != \"Name\" ]]; then
                echo \"Backing up: \$db\"
                sudo -u postgres pg_dump \"\$db\" 2>/dev/null > ~/temp_db_backup/\"\$db\"_$(date +%Y%m%d).sql || echo \"Skipped \$db (access denied)\"
            fi
        done
        ls -la ~/temp_db_backup/
    " || warning "Database backup may have failed - check permissions"
    
    # Download database backups
    rsync -avz --progress \
        "$PROD_USER@$PROD_SERVER:~/temp_db_backup/" \
        "$MIRROR_DIR/databases/" 2>/dev/null || warning "Database download may have failed"
    
    # Cleanup remote temp backups
    ssh "$PROD_USER@$PROD_SERVER" "rm -rf ~/temp_db_backup" || true
    
    success "Database backups completed"
}

# Create symlink for current mirror
create_current_link() {
    log "Creating 'current' symlink..."
    
    # Remove old current link if exists
    [[ -L "$CURRENT_LINK" ]] && sudo rm "$CURRENT_LINK"
    
    # Create new symlink
    sudo ln -sfn "$MIRROR_DIR" "$CURRENT_LINK"
    sudo chown -h "$USER:$USER" "$CURRENT_LINK"
    
    success "Current mirror linked at: $CURRENT_LINK"
}

# Create Apache virtual host for development
create_dev_vhost() {
    log "Creating development Apache configuration..."
    
    cat > "$MIRROR_DIR/apache-dev-site.conf" << EOF
# Apache Virtual Host for Production Mirror Development
# Copy to /etc/apache2/sites-available/ and enable with a2ensite

<VirtualHost *:80>
    ServerName dev.jxqz.local
    DocumentRoot $CURRENT_LINK/web-content/var-www/html
    
    <Directory "$CURRENT_LINK/web-content/var-www/html">
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    
    # User home directory access
    Alias /~steve $CURRENT_LINK/web-content/home-steve/public_html
    
    <Directory "$CURRENT_LINK/web-content/home-steve/public_html">
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    
    ErrorLog \${APACHE_LOG_DIR}/dev-jxqz-error.log
    CustomLog \${APACHE_LOG_DIR}/dev-jxqz-access.log combined
</VirtualHost>
EOF

    cat > "$MIRROR_DIR/setup-local-dev.sh" << 'EOF'
#!/bin/bash
# Setup local development environment

echo "Setting up local development from production mirror..."

# Copy Apache config
sudo cp apache-dev-site.conf /etc/apache2/sites-available/dev-jxqz.conf

# Enable site
sudo a2ensite dev-jxqz

# Add to hosts file for local access
echo "127.0.0.1 dev.jxqz.local" | sudo tee -a /etc/hosts

# Reload Apache
sudo systemctl reload apache2

echo "✅ Development site available at: http://dev.jxqz.local"
echo "📁 Document root: $(readlink -f current/web-content/var-www/html)"
EOF

    chmod +x "$MIRROR_DIR/setup-local-dev.sh"
    
    success "Development Apache configuration created"
}

# Generate comprehensive report
generate_report() {
    log "Generating mirror report..."
    
    local total_files=$(find "$MIRROR_DIR" -type f | wc -l)
    local total_size=$(du -sh "$MIRROR_DIR" | cut -f1)
    
    cat > "$MIRROR_DIR/MIRROR_REPORT.md" << EOF
# Production Mirror Report

**Date**: $(date)  
**Server**: $PROD_SERVER  
**Local Mirror**: $MIRROR_DIR  
**Total Size**: $total_size  
**Total Files**: $total_files  

## Mirror Location Strategy
- **Path**: \`/var/www/production-mirror/\`
- **Reason**: Root partition has sufficient space (79GB available)
- **Future**: Can be moved to dedicated storage when SSD added
- **Current Link**: \`$CURRENT_LINK\` → \`$MIRROR_DIR\`

## Contents Mirrored

### Web Content
\`\`\`
web-content/
├── var-www/          # Apache DocumentRoot content
└── home-steve/       # User home directory web files
    └── public_html/  # ~/public_html content
\`\`\`

### Databases
\`\`\`
databases/
└── *.sql            # PostgreSQL database dumps
\`\`\`

### Configuration
\`\`\`
config/
├── apache2/          # Web server configuration
├── ssl/              # SSL certificates
└── user/             # User-specific configs
\`\`\`

## Development Setup
1. Run: \`./setup-local-dev.sh\`
2. Access: http://dev.jxqz.local
3. Files: Edit directly in \`$CURRENT_LINK/web-content/\`

## Future Storage Migration
When adding dedicated SSD:
\`\`\`bash
# Mount new SSD to /mnt/storage
sudo mkdir -p /mnt/storage
sudo mount /dev/sdX1 /mnt/storage

# Move mirror data
sudo rsync -av /var/www/production-mirror/ /mnt/storage/production-mirror/

# Update symlink
sudo rm /var/www/production-mirror
sudo ln -s /mnt/storage/production-mirror /var/www/production-mirror
\`\`\`

## File Breakdown
EOF

    echo "### Directory Sizes" >> "$MIRROR_DIR/MIRROR_REPORT.md"
    du -sh "$MIRROR_DIR"/* 2>/dev/null >> "$MIRROR_DIR/MIRROR_REPORT.md" || echo "Size calculation failed" >> "$MIRROR_DIR/MIRROR_REPORT.md"
    
    echo "" >> "$MIRROR_DIR/MIRROR_REPORT.md"
    echo "### Recent Files" >> "$MIRROR_DIR/MIRROR_REPORT.md"
    find "$MIRROR_DIR/web-content" -name "*.php" -o -name "*.html" | head -10 >> "$MIRROR_DIR/MIRROR_REPORT.md" 2>/dev/null || true
    
    success "Mirror report: $MIRROR_DIR/MIRROR_REPORT.md"
}

# Main execution
main() {
    echo "🔄 Production Mirror to /var/www"
    echo "================================"
    echo ""
    
    if [[ "$PROD_SERVER" == "your-server-ip-or-domain" ]]; then
        error "Please provide your production server address:"
        echo "Usage: $0 <server-address>"
        echo "Example: $0 jxqz.org"
        echo "         $0 123.456.789.012"
        exit 1
    fi
    
    log "Starting production mirror to /var/www..."
    log "Production Server: $PROD_SERVER"
    log "Mirror Location: $MIRROR_DIR"
    
    check_prerequisites
    create_mirror_structure
    mirror_web_content
    mirror_databases
    create_current_link
    create_dev_vhost
    generate_report
    
    echo ""
    success "Production mirror completed successfully!"
    echo ""
    echo "📁 Mirror location: $MIRROR_DIR"
    echo "🔗 Current link: $CURRENT_LINK"
    echo "📊 Report: $MIRROR_DIR/MIRROR_REPORT.md"
    echo "🛠️  Dev setup: $MIRROR_DIR/setup-local-dev.sh"
    echo ""
    echo "💾 Total size: $(du -sh "$MIRROR_DIR" | cut -f1)"
    echo "🔗 Quick access: ls -la $CURRENT_LINK"
    echo ""
    echo "Next steps:"
    echo "1. Review: cat $MIRROR_DIR/MIRROR_REPORT.md"
    echo "2. Dev setup: cd $MIRROR_DIR && ./setup-local-dev.sh"
    echo "3. Later: Move to dedicated storage when SSD available"
}

# Check arguments
if [[ $# -eq 0 ]]; then
    echo "Usage: $0 <production-server-address>"
    echo ""
    echo "This mirrors production content to /var/www/production-mirror/"
    echo "Example: $0 jxqz.org"
    exit 0
fi

PROD_SERVER="$1"
main "$@"