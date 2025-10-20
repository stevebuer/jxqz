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

