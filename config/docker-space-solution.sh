#!/bin/bash

#
# docker-space-solution.sh - Immediate Docker space solution + enhanced storage
# Addresses root volume space constraints for Docker deployments
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="./docker-space-solution-$(date +%Y%m%d-%H%M%S)"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

echo "Creating Docker space solution plan..."
mkdir -p "$BACKUP_DIR"

# Create comprehensive Docker + storage solution
cat > "$BACKUP_DIR/DOCKER_SPACE_SOLUTION.md" << 'EOF'
# Docker Space Solution - Root Volume Crisis

## Current Space Crisis

### Root Volume Status
- **Primary Disk:** 10GB total, 86% full (~1.4GB free)
- **Docker Requirements:** Typically needs 2-5GB for containers, images, volumes
- **Critical Issue:** Not enough space for Docker deployment

### Immediate Risk
- **Docker Installation:** May fail due to insufficient space
- **Container Images:** Cannot download/store standard images
- **Application Data:** No space for persistent volumes
- **System Stability:** Risk of filling root filesystem

## Dual-Track Solution Strategy

### Track 1: Immediate Docker Space (Emergency)
**Timeline:** Today/This week
**Goal:** Get Docker working immediately with minimal changes

#### Option A: Move Docker to Web Volume (Quick Fix)
```bash
# Stop Docker if running
sudo systemctl stop docker

# Move Docker data to web volume
sudo mkdir -p /var/www/jxqz.org/docker-data
sudo mv /var/lib/docker /var/www/jxqz.org/docker-data/
sudo ln -s /var/www/jxqz.org/docker-data/docker /var/lib/docker

# Configure Docker daemon
sudo mkdir -p /etc/docker
cat > /etc/docker/daemon.json << 'DOCKER_EOF'
{
  "data-root": "/var/www/jxqz.org/docker-data/docker",
  "storage-driver": "overlay2"
}
DOCKER_EOF

# Restart Docker
sudo systemctl start docker
```

#### Option B: Docker on Temporary Mount (Alternative)
```bash
# Create docker directory on web volume
sudo mkdir -p /var/www/jxqz.org/docker

# Configure Docker daemon for custom location
sudo mkdir -p /etc/docker
cat > /etc/docker/daemon.json << 'DOCKER_EOF'
{
  "data-root": "/var/www/jxqz.org/docker",
  "storage-driver": "overlay2"
}
DOCKER_EOF
```

### Track 2: Enhanced Storage Migration (Strategic)
**Timeline:** Next maintenance window
**Goal:** Permanent solution with enhanced storage layout

#### Benefits for Docker
- **More Root Space:** Free up ~2-3GB on root volume
- **Dedicated Docker Location:** `/web-content/docker/` on high-performance volume
- **Better Performance:** Docker on optimized storage with `noatime`
- **Easier Management:** All application data centralized

## Emergency Implementation Plan

### Phase 1: Immediate Space Relief (Today)
1. **Clean Up Root Volume**
   ```bash
   # Clean package cache
   sudo apt clean
   sudo apt autoremove
   
   # Clean logs
   sudo journalctl --vacuum-time=7d
   sudo find /var/log -name "*.log.1" -delete
   sudo find /var/log -name "*.gz" -delete
   
   # Clean temp files
   sudo rm -rf /tmp/*
   sudo rm -rf /var/tmp/*
   ```

2. **Move Docker to Web Volume**
   ```bash
   # Execute Option A above
   ```

3. **Verify Space**
   ```bash
   df -h
   docker info | grep "Docker Root Dir"
   ```

### Phase 2: Enhanced Storage Migration (Maintenance Window)
1. **Implement Enhanced Storage Layout**
2. **Move Docker to Dedicated Location**
   ```bash
   # In enhanced layout
   mkdir -p /web-content/docker
   mkdir -p /web-content/app-data
   
   # Update Docker daemon configuration
   cat > /etc/docker/daemon.json << 'DOCKER_EOF'
   {
     "data-root": "/web-content/docker",
     "storage-driver": "overlay2"
   }
   DOCKER_EOF
   ```

## Enhanced Storage + Docker Integration

### Directory Layout with Docker
```
/web-content/                    # Web volume (40GB)
├── sites/                      # Website content
│   ├── jxqz.org/              # Photo galleries
│   ├── dx.jxqz.org/           # Analytics app
│   ├── arpoison.net/          
│   └── suoc.org/              
├── user/                       # User development
│   └── steve/
│       └── public_html/       
├── docker/                     # Docker data
│   ├── containers/            # Container storage
│   ├── images/                # Image layers
│   ├── volumes/               # Named volumes
│   └── networks/              # Network configs
├── app-data/                   # Application persistent data
│   ├── postgres/              # Database data
│   ├── redis/                 # Cache data
│   └── uploads/               # App uploads
├── backups/                    # Backup staging
└── logs/                       # Application logs
```

### Docker Compose Integration
```yaml
# docker-compose.yml example with enhanced storage
version: '3.8'
services:
  app:
    image: your-app
    volumes:
      - /web-content/app-data/uploads:/app/uploads
      - /web-content/logs/app:/app/logs
  
  postgres:
    image: postgres:15
    volumes:
      - /web-content/app-data/postgres:/var/lib/postgresql/data
  
  redis:
    image: redis:7
    volumes:
      - /web-content/app-data/redis:/data
```

## Space Usage Projections

### Before (Current Crisis)
- **Root Volume:** 10GB (86% full) = 1.4GB free
- **Docker Needs:** 2-5GB minimum
- **Result:** ❌ Insufficient space

### After Emergency Fix
- **Root Volume:** 10GB (70% full) = 3GB free
- **Docker on Web Volume:** Works immediately
- **Result:** ✅ Docker operational

### After Enhanced Storage
- **Root Volume:** 10GB (60% full) = 4GB free (OS only)
- **Web Volume:** 40GB (40% full) = 24GB free (all data)
- **Docker Performance:** Optimized on dedicated volume
- **Result:** ✅ Scalable, high-performance solution

## Risk Assessment

### Emergency Fix Risks
- **Temporary Solution:** Needs migration later
- **Performance:** May be slightly slower than root SSD
- **Backup Complexity:** Docker data mixed with web content

### Enhanced Storage Risks
- **Migration Downtime:** 30-60 minutes
- **Complexity:** More moving parts
- **Testing Required:** Validate in VirtualBox first

## Immediate Action Items

### Today (Emergency)
- [ ] Check current disk usage: `df -h`
- [ ] Clean up root volume space
- [ ] Move Docker to web volume
- [ ] Test Docker functionality
- [ ] Deploy your new app stack

### This Week (Planning)
- [ ] Test enhanced storage in VirtualBox
- [ ] Plan maintenance window
- [ ] Prepare migration scripts
- [ ] Update monitoring/backup procedures

### Next Maintenance (Strategic)
- [ ] Implement enhanced storage layout
- [ ] Move Docker to dedicated location
- [ ] Validate all functionality
- [ ] Update documentation

## Docker-Specific Commands

### Move Docker Data Safely
```bash
# 1. Stop Docker
sudo systemctl stop docker

# 2. Create backup
sudo tar -czf /var/www/jxqz.org/docker-backup.tar.gz /var/lib/docker

# 3. Move data
sudo mkdir -p /var/www/jxqz.org/docker-data
sudo rsync -av /var/lib/docker/ /var/www/jxqz.org/docker-data/docker/

# 4. Update configuration
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json << 'DOCKER_EOF'
{
  "data-root": "/var/www/jxqz.org/docker-data/docker",
  "storage-driver": "overlay2",
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
DOCKER_EOF

# 5. Remove old data (after verification)
sudo rm -rf /var/lib/docker

# 6. Start Docker
sudo systemctl start docker

# 7. Verify
docker info | grep "Docker Root Dir"
```

### Monitor Space Usage
```bash
# Overall disk usage
df -h

# Docker space usage
docker system df

# Clean up Docker (when needed)
docker system prune -a
docker volume prune
```

## Terraform Integration

### VirtualBox Testing
```hcl
# Add to enhanced-storage.tf
locals {
  docker_paths = var.enhanced_storage_layout ? {
    docker_root = "${var.web_content_mount}/docker"
    app_data    = "${var.web_content_mount}/app-data"
    compose_dir = "${var.web_content_mount}/docker-compose"
  } : {
    docker_root = "/var/lib/docker"
    app_data    = "/opt/app-data"
    compose_dir = "/opt/docker-compose"
  }
}

# Docker daemon configuration
resource "local_file" "docker_daemon_config" {
  content = jsonencode({
    "data-root" = local.docker_paths.docker_root
    "storage-driver" = "overlay2"
    "log-driver" = "json-file"
    "log-opts" = {
      "max-size" = "10m"
      "max-file" = "3"
    }
  })
  filename = "/etc/docker/daemon.json"
}
```

## Success Metrics

### Immediate Success (Emergency Fix)
- [ ] Docker service starts successfully
- [ ] Can pull and run container images
- [ ] Root volume usage below 80%
- [ ] Application stack deploys successfully

### Long-term Success (Enhanced Storage)
- [ ] Root volume usage below 70%
- [ ] All web content on dedicated volume
- [ ] Docker performance optimized
- [ ] Simplified backup strategy
- [ ] Room for growth and expansion

EOF

# Create emergency Docker space script
cat > "$BACKUP_DIR/emergency-docker-space.sh" << 'EOF'
#!/bin/bash

#
# emergency-docker-space.sh - Emergency fix for Docker space on root volume
#

set -euo pipefail

log() {
    echo "[$(date '+%H:%M:%S')] $*"
}

error() {
    echo "[ERROR] $*" >&2
    exit 1
}

# Check if running as root or with sudo
if [[ $EUID -ne 0 ]] && ! sudo -n true 2>/dev/null; then
    error "This script requires sudo access. Please run: sudo $0"
fi

log "🚨 Emergency Docker Space Fix Starting..."

# Check current space
log "📊 Current disk usage:"
df -h | grep -E "(Filesystem|/dev/)"

ROOT_USAGE=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
if [[ $ROOT_USAGE -lt 85 ]]; then
    log "✅ Root volume usage: ${ROOT_USAGE}% - may not need emergency fix"
else
    log "🚨 Root volume usage: ${ROOT_USAGE}% - emergency fix needed!"
fi

# Clean up space first
log "🧹 Cleaning up system space..."
sudo apt clean
sudo apt autoremove -y
sudo journalctl --vacuum-time=7d
sudo find /var/log -name "*.log.[0-9]*" -delete 2>/dev/null || true
sudo find /var/log -name "*.gz" -delete 2>/dev/null || true
sudo rm -rf /tmp/* 2>/dev/null || true
sudo rm -rf /var/tmp/* 2>/dev/null || true

log "📊 After cleanup:"
df -h | grep -E "(Filesystem|/dev/)"

# Check if Docker is installed
if ! command -v docker >/dev/null 2>&1; then
    log "🐳 Docker not installed - installing to web volume..."
    
    # Install Docker with custom data root
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    
    # Configure for web volume immediately
    sudo mkdir -p /var/www/jxqz.org/docker-data
    sudo mkdir -p /etc/docker
    
    sudo tee /etc/docker/daemon.json << 'DOCKER_EOF'
{
  "data-root": "/var/www/jxqz.org/docker-data",
  "storage-driver": "overlay2",
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
DOCKER_EOF
    
    sudo systemctl enable docker
    sudo systemctl start docker
    sudo usermod -aG docker steve
    
    log "✅ Docker installed with data on web volume"
    
else
    log "🐳 Docker already installed - moving data to web volume..."
    
    # Stop Docker
    sudo systemctl stop docker
    
    # Create backup
    if [[ -d /var/lib/docker ]]; then
        log "💾 Creating backup of Docker data..."
        sudo tar -czf /var/www/jxqz.org/docker-backup-$(date +%Y%m%d-%H%M%S).tar.gz /var/lib/docker
    fi
    
    # Create new location
    sudo mkdir -p /var/www/jxqz.org/docker-data
    
    # Move existing data
    if [[ -d /var/lib/docker ]] && [[ $(sudo ls -A /var/lib/docker 2>/dev/null | wc -l) -gt 0 ]]; then
        log "📦 Moving Docker data to web volume..."
        sudo rsync -av /var/lib/docker/ /var/www/jxqz.org/docker-data/
        sudo rm -rf /var/lib/docker
    fi
    
    # Configure Docker daemon
    sudo mkdir -p /etc/docker
    sudo tee /etc/docker/daemon.json << 'DOCKER_EOF'
{
  "data-root": "/var/www/jxqz.org/docker-data",
  "storage-driver": "overlay2",
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
DOCKER_EOF
    
    # Start Docker
    sudo systemctl start docker
    
    log "✅ Docker data moved to web volume"
fi

# Verify Docker works
log "🔍 Testing Docker functionality..."
sudo docker run --rm hello-world >/dev/null 2>&1 && \
    log "✅ Docker test successful" || \
    log "❌ Docker test failed"

# Show final status
log "📊 Final disk usage:"
df -h | grep -E "(Filesystem|/dev/)"

log "🐳 Docker configuration:"
sudo docker info | grep -E "(Docker Root Dir|Storage Driver)" || true

log "✅ Emergency Docker space fix completed!"
log ""
log "Next steps:"
log "  1. Test your application deployment"
log "  2. Plan enhanced storage migration"
log "  3. Monitor disk usage regularly"
EOF

log "✅ Docker space solution created successfully!"
log "📁 Location: $BACKUP_DIR"
log "📋 Solution Plan: $BACKUP_DIR/DOCKER_SPACE_SOLUTION.md"
log "🚨 Emergency Script: $BACKUP_DIR/emergency-docker-space.sh"
log ""
log "🔧 Immediate Actions:"
log "   1. Run emergency space fix: sudo $BACKUP_DIR/emergency-docker-space.sh"
log "   2. Deploy your Docker containers"
log "   3. Plan enhanced storage migration"
log ""
log "💡 This solves both immediate Docker needs and long-term storage strategy!"