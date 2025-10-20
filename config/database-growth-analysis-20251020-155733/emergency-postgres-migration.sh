#!/bin/bash

#
# emergency-postgres-migration.sh - Move PostgreSQL off root volume immediately
#

set -euo pipefail

log() {
    echo "[$(date '+%H:%M:%S')] $*"
}

error() {
    echo "[ERROR] $*" >&2
    exit 1
}

# Check if running with sudo
if [[ $EUID -ne 0 ]] && ! sudo -n true 2>/dev/null; then
    error "This script requires sudo access. Please run: sudo $0"
fi

log "🚨 Emergency PostgreSQL Migration Starting..."

# Check current space
log "📊 Current disk usage:"
df -h | grep -E "(Filesystem|/dev/)"

# Check PostgreSQL status
if ! systemctl is-active --quiet postgresql; then
    log "⚠️ PostgreSQL not running, starting it first..."
    sudo systemctl start postgresql
    sleep 2
fi

# Get current database size
DB_SIZE=$(sudo du -sh /var/lib/postgresql 2>/dev/null | cut -f1)
log "📊 Current PostgreSQL size: $DB_SIZE"

# Create backup first
log "💾 Creating full database backup..."
sudo mkdir -p /var/www/jxqz.org/backups
BACKUP_FILE="/var/www/jxqz.org/backups/postgres-full-backup-$(date +%Y%m%d-%H%M%S).sql"
sudo -u postgres pg_dumpall > "$BACKUP_FILE"
log "✅ Backup created: $BACKUP_FILE"

# Stop services using database
log "🛑 Stopping services..."
sudo systemctl stop apache2 2>/dev/null || log "Apache2 not running or already stopped"
sudo systemctl stop postgresql

# Create new location
log "📁 Creating new PostgreSQL location on web volume..."
sudo mkdir -p /var/www/jxqz.org/databases/postgresql
sudo chown postgres:postgres /var/www/jxqz.org/databases/postgresql
sudo chmod 700 /var/www/jxqz.org/databases/postgresql

# Move data safely
log "📦 Moving PostgreSQL data to web volume..."
sudo rsync -av /var/lib/postgresql/ /var/www/jxqz.org/databases/postgresql/

# Create symlink (preserves all existing paths)
log "🔗 Creating symlink to maintain compatibility..."
sudo mv /var/lib/postgresql /var/lib/postgresql.backup-$(date +%Y%m%d-%H%M%S)
sudo ln -s /var/www/jxqz.org/databases/postgresql /var/lib/postgresql

# Start PostgreSQL
log "🚀 Starting PostgreSQL..."
sudo systemctl start postgresql

# Wait for PostgreSQL to be ready
log "⏳ Waiting for PostgreSQL to be ready..."
timeout=30
while ! sudo -u postgres psql -c "SELECT 1;" >/dev/null 2>&1; do
    sleep 1
    timeout=$((timeout - 1))
    if [ $timeout -le 0 ]; then
        error "PostgreSQL failed to start properly"
    fi
done

log "✅ PostgreSQL started successfully"

# Verify database integrity
log "🔍 Verifying database integrity..."
sudo -u postgres psql -c "
SELECT 
    datname as database,
    pg_size_pretty(pg_database_size(datname)) as size
FROM pg_database 
WHERE datistemplate = false
ORDER BY pg_database_size(datname) DESC;"

# Start web services
log "🌐 Starting web services..."
sudo systemctl start apache2

# Show final status
log "📊 Final disk usage:"
df -h | grep -E "(Filesystem|/dev/)"

# Show PostgreSQL location
log "📍 PostgreSQL now located at:"
ls -la /var/lib/postgresql
echo "  → Points to: $(readlink /var/lib/postgresql)"

log "✅ Emergency PostgreSQL migration completed!"
log ""
log "Space freed on root volume: ~$DB_SIZE"
log "PostgreSQL data now on web volume with 30GB+ available space"
log ""
log "Next steps:"
log "  1. Test dx-cluster app functionality"
log "  2. Monitor database performance"
log "  3. Run Docker emergency fix if needed"
log "  4. Plan enhanced storage migration"
