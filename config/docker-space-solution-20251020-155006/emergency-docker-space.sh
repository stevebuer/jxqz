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
