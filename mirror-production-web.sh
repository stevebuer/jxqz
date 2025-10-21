#!/bin/bash

#
# mirror-production-web.sh - Mirror production web content for backup and development
#
# This script creates a complete mirror of your production web content
# for safety before making any infrastructure changes.
#

set -euo pipefail

# Configuration
PROD_SERVER="your-server-ip-or-domain"
PROD_USER="steve"
LOCAL_MIRROR_BASE="/home/steve/PRODUCTION_MIRROR"
DATE_STAMP=$(date '+%Y-%m-%d_%H-%M-%S')
MIRROR_DIR="$LOCAL_MIRROR_BASE/$DATE_STAMP"

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

# Create mirror directory structure
create_mirror_structure() {
    log "Creating mirror directory structure..."
    mkdir -p "$MIRROR_DIR"/{web-content,databases,config,logs}
    echo "Production Mirror - $(date)" > "$MIRROR_DIR/README.md"
    echo "Server: $PROD_SERVER" >> "$MIRROR_DIR/README.md"
    echo "User: $PROD_USER" >> "$MIRROR_DIR/README.md"
}

# Mirror web content
mirror_web_content() {
    log "Mirroring web content..."
    
    # Apache DocumentRoot and sites
    log "Syncing /var/www/..."
    rsync -avz --progress --stats \
        "$PROD_USER@$PROD_SERVER:/var/www/" \
        "$MIRROR_DIR/web-content/var-www/" \
        --exclude="*.log" \
        --exclude="cache/*" \
        --exclude="tmp/*" || warning "Some files in /var/www may not be accessible"
    
    # User home directory web content (~/public_html, ~/www, etc.)
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
        --include="*.txt" \
        --exclude="*" || warning "Some user files may not be accessible"
    
    success "Web content mirrored"
}

# Mirror databases
mirror_databases() {
    log "Creating database backups..."
    
    # PostgreSQL databases
    log "Backing up PostgreSQL databases..."
    ssh "$PROD_USER@$PROD_SERVER" "
        mkdir -p ~/temp_backups
        # List all databases and backup each one
        sudo -u postgres psql -l -t | cut -d'|' -f1 | sed 's/^ *//g' | grep -v '^$' | grep -v 'template' | grep -v 'postgres' | while read db; do
            echo \"Backing up database: \$db\"
            sudo -u postgres pg_dump \"\$db\" > ~/temp_backups/\"\$db\"_$(date +%Y%m%d).sql 2>/dev/null || echo \"Could not backup \$db\"
        done
    " || warning "Database backup may have failed - check permissions"
    
    # Download database backups
    rsync -avz --progress \
        "$PROD_USER@$PROD_SERVER:~/temp_backups/" \
        "$MIRROR_DIR/databases/" || warning "Database download may have failed"
    
    # Cleanup remote temp backups
    ssh "$PROD_USER@$PROD_SERVER" "rm -rf ~/temp_backups" || true
    
    success "Database backups completed"
}

# Mirror critical configuration
mirror_config() {
    log "Mirroring critical configuration files..."
    
    # Apache configuration
    rsync -avz --progress \
        "$PROD_USER@$PROD_SERVER:/etc/apache2/" \
        "$MIRROR_DIR/config/apache2/" || warning "Apache config may not be accessible"
    
    # SSL certificates
    rsync -avz --progress \
        "$PROD_USER@$PROD_SERVER:/etc/ssl/" \
        "$MIRROR_DIR/config/ssl/" || warning "SSL config may not be accessible"
    
    # Dovecot (email) configuration
    rsync -avz --progress \
        "$PROD_USER@$PROD_SERVER:/etc/dovecot/" \
        "$MIRROR_DIR/config/dovecot/" || warning "Dovecot config may not be accessible"
    
    # Crontab and user configurations
    ssh "$PROD_USER@$PROD_SERVER" "
        crontab -l > ~/crontab_backup.txt 2>/dev/null || echo '# No crontab found' > ~/crontab_backup.txt
        cp ~/.bashrc ~/bashrc_backup.txt 2>/dev/null || echo '# No .bashrc found' > ~/bashrc_backup.txt
        cp ~/.profile ~/profile_backup.txt 2>/dev/null || echo '# No .profile found' > ~/profile_backup.txt
    "
    
    rsync -avz --progress \
        "$PROD_USER@$PROD_SERVER:~/*_backup.txt" \
        "$MIRROR_DIR/config/user/" || warning "User config may not be accessible"
    
    success "Configuration mirrored"
}

# Create development environment setup
create_dev_setup() {
    log "Creating development environment setup..."
    
    cat > "$MIRROR_DIR/setup-dev-environment.sh" << 'EOF'
#!/bin/bash
#
# Setup Development Environment from Production Mirror
#
echo "Setting up development environment from production mirror..."

# This script will help you set up a local development environment
# based on the mirrored production content.

echo "Production mirror contents:"
echo "- web-content/: All website files from production"
echo "- databases/: Database backups (SQL files)"
echo "- config/: Server configuration files"
echo "- logs/: Selected log files for analysis"

echo ""
echo "Next steps:"
echo "1. Review web-content/ directory structure"
echo "2. Set up local Apache/Nginx to serve content"
echo "3. Import database backups into local PostgreSQL"
echo "4. Adapt configuration for local development"
echo "5. Create git repository for ongoing development"

echo ""
echo "Consider creating a Docker development environment based on this content."
EOF
    
    chmod +x "$MIRROR_DIR/setup-dev-environment.sh"
    
    success "Development setup script created"
}

# Generate mirror report
generate_report() {
    log "Generating mirror report..."
    
    cat > "$MIRROR_DIR/MIRROR_REPORT.md" << EOF
# Production Mirror Report

**Date**: $(date)
**Server**: $PROD_SERVER
**Local Mirror**: $MIRROR_DIR

## Contents Mirrored

### Web Content
- \`web-content/var-www/\` - Apache DocumentRoot content
- \`web-content/home-steve/\` - User home directory web files

### Databases  
- \`databases/\` - PostgreSQL database backups

### Configuration
- \`config/apache2/\` - Apache web server configuration
- \`config/ssl/\` - SSL certificate configuration  
- \`config/dovecot/\` - Email server configuration
- \`config/user/\` - User-specific configuration files

## File Counts
EOF
    
    find "$MIRROR_DIR" -type f | wc -l >> "$MIRROR_DIR/MIRROR_REPORT.md"
    echo " total files mirrored" >> "$MIRROR_DIR/MIRROR_REPORT.md"
    echo "" >> "$MIRROR_DIR/MIRROR_REPORT.md"
    
    echo "### Directory Sizes" >> "$MIRROR_DIR/MIRROR_REPORT.md"
    du -sh "$MIRROR_DIR"/* >> "$MIRROR_DIR/MIRROR_REPORT.md"
    
    success "Mirror report generated: $MIRROR_DIR/MIRROR_REPORT.md"
}

# Main execution
main() {
    echo "🔄 Production Web Content Mirror"
    echo "================================"
    echo ""
    
    if [[ "$PROD_SERVER" == "your-server-ip-or-domain" ]]; then
        error "Please edit this script and set your production server details:"
        echo "  PROD_SERVER=\"your.actual.server.com\""
        echo "  PROD_USER=\"your-username\""
        exit 1
    fi
    
    log "Starting production mirror process..."
    log "Production Server: $PROD_SERVER"
    log "Mirror Location: $MIRROR_DIR"
    
    create_mirror_structure
    mirror_web_content
    mirror_databases  
    mirror_config
    create_dev_setup
    generate_report
    
    echo ""
    success "Production mirror completed successfully!"
    echo ""
    echo "📁 Mirror location: $MIRROR_DIR"
    echo "📊 Report: $MIRROR_DIR/MIRROR_REPORT.md"
    echo "🛠️  Dev setup: $MIRROR_DIR/setup-dev-environment.sh"
    echo ""
    echo "Next steps:"
    echo "1. Review the mirror report"
    echo "2. Set up local development environment"  
    echo "3. Create git repository from mirrored content"
    echo "4. Establish regular backup schedule"
}

# Show usage if no arguments
if [[ $# -eq 0 ]]; then
    echo "Usage: $0 [production-server-address]"
    echo ""
    echo "Example: $0 jxqz.org"
    echo "         $0 123.456.789.012"
    echo ""
    echo "This will mirror all web content, databases, and configuration"
    echo "from your production server for backup and development."
    exit 0
fi

# Set production server from command line if provided
if [[ $# -gt 0 ]]; then
    PROD_SERVER="$1"
fi

main "$@"