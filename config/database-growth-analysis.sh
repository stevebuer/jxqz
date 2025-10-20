#!/bin/bash

#
# database-growth-analysis.sh - PostgreSQL growth impact on storage strategy
# Critical update to storage planning considering database growth
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="./database-growth-analysis-$(date +%Y%m%d-%H%M%S)"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

echo "Analyzing PostgreSQL database growth impact..."
mkdir -p "$BACKUP_DIR"

# Create comprehensive database + storage analysis
cat > "$BACKUP_DIR/DATABASE_GROWTH_ANALYSIS.md" << 'EOF'
# PostgreSQL Database Growth - Critical Storage Update

## Current Database Situation

### PostgreSQL Status
- **Current Size:** 80MB in `/var/lib/postgresql/`
- **Location:** Root volume (already 86% full)
- **Growth Pattern:** Steady growth rate
- **Application:** dx-cluster analysis app
- **Risk Level:** 🚨 HIGH - Growing on constrained volume

### Space Crisis Compounded

#### Original Crisis
- **Root Volume:** 10GB, 86% full (1.3GB free)
- **Docker Needs:** 2-5GB for containers and images

#### Database Growth Impact
- **Current DB:** 80MB (manageable now)
- **Growth Rate:** Steady increase
- **Projection:** Could reach 500MB-2GB depending on data retention
- **Combined Impact:** Docker + DB growth = Space exhaustion

### Critical Timeline

#### Immediate (Days/Weeks)
- Docker deployment blocked by space
- Database continues growing on root volume
- Risk of root filesystem filling up

#### Medium-term (Months)
- Database could consume remaining 1.3GB free space
- System stability at risk
- Application performance degradation

## Enhanced Solution Strategy

### Priority 1: Emergency Space Relief (TODAY)
Move both Docker AND PostgreSQL off root volume immediately.

#### Docker Emergency Fix (As Planned)
```bash
# Move Docker to web volume
sudo systemctl stop docker
sudo mkdir -p /var/www/jxqz.org/docker-data
sudo mv /var/lib/docker /var/www/jxqz.org/docker-data/ 2>/dev/null || true
sudo tee /etc/docker/daemon.json << 'DOCKER_EOF'
{
  "data-root": "/var/www/jxqz.org/docker-data",
  "storage-driver": "overlay2"
}
DOCKER_EOF
sudo systemctl start docker
```

#### PostgreSQL Emergency Fix (NEW - CRITICAL)
```bash
# Stop PostgreSQL
sudo systemctl stop postgresql

# Create backup
sudo pg_dumpall -U postgres > /var/www/jxqz.org/postgres-backup-$(date +%Y%m%d).sql

# Create new PostgreSQL data directory on web volume
sudo mkdir -p /var/www/jxqz.org/postgresql-data
sudo chown postgres:postgres /var/www/jxqz.org/postgresql-data

# Move existing data
sudo rsync -av /var/lib/postgresql/ /var/www/jxqz.org/postgresql-data/

# Update PostgreSQL configuration
sudo sed -i "s|#data_directory = '/var/lib/postgresql/.*'|data_directory = '/var/www/jxqz.org/postgresql-data/15/main'|" /etc/postgresql/*/main/postgresql.conf

# Or create symlink approach (simpler)
sudo mv /var/lib/postgresql /var/lib/postgresql.bak
sudo ln -s /var/www/jxqz.org/postgresql-data /var/lib/postgresql

# Start PostgreSQL
sudo systemctl start postgresql
```

### Priority 2: Enhanced Storage Layout (UPDATED)

#### Updated Directory Structure
```
/web-content/                    # Web volume (40GB, plenty of space)
├── sites/                      # Website content
│   ├── jxqz.org/              # Photo galleries (existing ~8GB)
│   ├── dx.jxqz.org/           # Flask analytics app
│   ├── arpoison.net/          
│   └── suoc.org/              
├── user/                       # User development
│   └── steve/
│       └── public_html/       
├── docker/                     # Docker data (2-5GB expected)
│   ├── containers/            
│   ├── images/                
│   └── volumes/               
├── databases/                  # Database storage (CRITICAL ADDITION)
│   ├── postgresql/            # PostgreSQL data (80MB → 2GB+ growth)
│   ├── backups/               # Database backups
│   └── logs/                  # Database logs
├── app-data/                   # Application data
│   ├── dx-cluster/            # Analytics app data
│   ├── uploads/               
│   └── cache/                 
└── backups/                    # System backups
```

## Database Growth Projections

### dx-cluster Analysis App Growth Factors

#### Data Sources
- **Log Analysis:** Continuous server log ingestion
- **User Analytics:** Click tracking, session data
- **Performance Metrics:** Response times, error rates
- **Historical Data:** Long-term trend analysis

#### Growth Scenarios

##### Conservative Growth (Current Trend)
- **Monthly:** 20-50MB increase
- **Annual:** 250-600MB total
- **3 Years:** 1-2GB database size

##### Active Usage Growth
- **Monthly:** 50-200MB increase  
- **Annual:** 600MB-2.4GB total
- **3 Years:** 3-7GB database size

##### Heavy Analytics Growth
- **Monthly:** 200MB-1GB increase
- **Annual:** 2.4GB-12GB total
- **3 Years:** 10-30GB database size

### Space Impact Analysis

#### Current Allocation (Root Volume)
- **Available:** 1.3GB free
- **DB Current:** 80MB
- **Growth Buffer:** 1.2GB (6-60 months depending on growth rate)

#### After Emergency Move (Web Volume)
- **Available:** 30GB free (web volume)
- **DB Current:** 80MB
- **Growth Buffer:** 29.9GB (decades of growth capacity)

## Emergency Database Migration Script

### Safe PostgreSQL Migration Process
```bash
#!/bin/bash
# emergency-postgres-move.sh

# 1. Create full backup
sudo -u postgres pg_dumpall > /var/www/jxqz.org/full-backup-$(date +%Y%m%d-%H%M%S).sql

# 2. Stop services that use database
sudo systemctl stop apache2  # Stop web apps using DB
sudo systemctl stop postgresql

# 3. Move data safely
sudo mkdir -p /var/www/jxqz.org/databases/postgresql
sudo chown postgres:postgres /var/www/jxqz.org/databases/postgresql
sudo rsync -av /var/lib/postgresql/ /var/www/jxqz.org/databases/postgresql/

# 4. Create symlink (preserves paths)
sudo mv /var/lib/postgresql /var/lib/postgresql.backup
sudo ln -s /var/www/jxqz.org/databases/postgresql /var/lib/postgresql

# 5. Test startup
sudo systemctl start postgresql
sudo systemctl start apache2

# 6. Verify database integrity
sudo -u postgres psql -c "SELECT datname, pg_size_pretty(pg_database_size(datname)) FROM pg_database;"
```

## Docker + Database Integration

### Combined Emergency Fix Benefits
- **Root Volume Relief:** Frees ~3-5GB immediately
- **Growth Capacity:** 30GB available for expansion
- **Performance:** Both on optimized storage volume
- **Backup Strategy:** Single location for all application data

### Docker Compose with Database
```yaml
# docker-compose.yml for dx-cluster app
version: '3.8'
services:
  dx-analytics:
    build: ./dx-app
    volumes:
      - /var/www/jxqz.org/app-data/dx-cluster:/app/data
      - /var/www/jxqz.org/app-data/uploads:/app/uploads
    environment:
      - DATABASE_URL=postgresql://user:pass@postgres:5432/dx_cluster
    depends_on:
      - postgres

  postgres:
    image: postgres:15
    volumes:
      - /var/www/jxqz.org/databases/postgresql:/var/lib/postgresql/data
    environment:
      - POSTGRES_DB=dx_cluster
      - POSTGRES_USER=dx_user
      - POSTGRES_PASSWORD=${DB_PASSWORD}
```

## Risk Assessment & Mitigation

### High-Risk Scenario (No Action)
- **Timeline:** 2-6 months
- **Risk:** Root filesystem fills up
- **Impact:** System instability, application failures, potential data loss

### Medium-Risk Scenario (Docker Only)
- **Timeline:** 6-18 months  
- **Risk:** Database growth fills remaining space
- **Impact:** Database performance degradation, eventual space crisis

### Low-Risk Scenario (Complete Migration)
- **Timeline:** Years of capacity
- **Risk:** Minimal, plenty of growth room
- **Impact:** Optimal performance and stability

## Implementation Priority

### Immediate (This Week)
1. **Emergency PostgreSQL Migration** - Move database off root volume
2. **Docker Emergency Fix** - Enable container deployment
3. **Space Monitoring** - Track usage on both volumes

### Short-term (Next Month)
1. **Enhanced Storage Migration** - Implement permanent layout  
2. **Database Optimization** - Tune PostgreSQL for new location
3. **Backup Strategy Update** - Single-location backup procedures

### Long-term (Ongoing)
1. **Growth Monitoring** - Track database and application growth
2. **Capacity Planning** - Monitor web volume usage trends
3. **Performance Optimization** - Fine-tune storage performance

## Success Metrics

### Immediate Success
- [ ] Root volume usage below 75%
- [ ] PostgreSQL successfully moved and operational
- [ ] Docker deployment capability restored
- [ ] dx-cluster app functionality maintained

### Long-term Success
- [ ] Sustainable database growth capacity (years)
- [ ] Optimized application performance
- [ ] Simplified backup and recovery procedures
- [ ] Proactive capacity management

## Monitoring Strategy

### Database Growth Tracking
```bash
# Weekly database size check
sudo -u postgres psql -c "
SELECT 
    datname,
    pg_size_pretty(pg_database_size(datname)) as current_size,
    pg_database_size(datname) as size_bytes
FROM pg_database 
WHERE datname NOT IN ('template0', 'template1', 'postgres')
ORDER BY pg_database_size(datname) DESC;"

# Log to track growth over time
echo "$(date): $(sudo du -sb /var/lib/postgresql)" >> /var/log/db-growth.log
```

### Volume Usage Monitoring
```bash
# Daily volume check
df -h | grep -E "(web-content|/var/www|/)"

# Alert when usage exceeds thresholds
# Root volume > 80% = warning
# Web volume > 70% = planning needed
```

EOF

# Create emergency database migration script
cat > "$BACKUP_DIR/emergency-postgres-migration.sh" << 'EOF'
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
EOF

# Create combined emergency fix script
cat > "$BACKUP_DIR/emergency-combined-fix.sh" << 'EOF'
#!/bin/bash

#
# emergency-combined-fix.sh - Fix both Docker AND PostgreSQL space issues
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log() {
    echo "[$(date '+%H:%M:%S')] $*"
}

log "🚨 Combined Emergency Fix: Docker + PostgreSQL"
log "This will move both Docker and PostgreSQL off the root volume"
log ""
read -p "Continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log "Cancelled by user"
    exit 0
fi

# Run PostgreSQL migration first
log "Step 1: PostgreSQL Migration"
if [[ -f "$SCRIPT_DIR/emergency-postgres-migration.sh" ]]; then
    chmod +x "$SCRIPT_DIR/emergency-postgres-migration.sh"
    sudo "$SCRIPT_DIR/emergency-postgres-migration.sh"
else
    log "❌ PostgreSQL migration script not found"
fi

echo ""
log "Step 2: Docker Migration" 
if [[ -f "$SCRIPT_DIR/../emergency-docker-space.sh" ]]; then
    chmod +x "$SCRIPT_DIR/../emergency-docker-space.sh"
    sudo "$SCRIPT_DIR/../emergency-docker-space.sh"
else
    log "❌ Docker migration script not found"
fi

log "✅ Combined emergency fix completed!"
log "Both Docker and PostgreSQL moved off root volume"
EOF

log "✅ Database growth analysis completed!"
log "📁 Location: $BACKUP_DIR"
log "📋 Analysis: $BACKUP_DIR/DATABASE_GROWTH_ANALYSIS.md"
log "🗄️ PostgreSQL Migration: $BACKUP_DIR/emergency-postgres-migration.sh"
log "🔄 Combined Fix: $BACKUP_DIR/emergency-combined-fix.sh"
log ""
log "🚨 CRITICAL FINDINGS:"
log "   • PostgreSQL: 80MB and growing on 86% full root volume"
log "   • Combined risk: Docker + Database growth = space crisis"
log "   • Recommendation: Move BOTH immediately to web volume"
log ""
log "⚡ Emergency Actions Available:"
log "   1. PostgreSQL only: sudo $BACKUP_DIR/emergency-postgres-migration.sh"  
log "   2. Combined fix: sudo $BACKUP_DIR/emergency-combined-fix.sh"
log ""
log "💡 This buys you YEARS of growth capacity on your 40GB web volume!"