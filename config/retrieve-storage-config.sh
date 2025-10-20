#!/bin/bash

#
# retrieve-storage-config.sh - Get storage configuration information
# Documents storage layout, mount points, and volume configurations
#

set -euo pipefail

REMOTE_SERVER="${1:-jxqz.org}"
REMOTE_USER="${REMOTE_USER:-steve}"
BACKUP_DIR="./storage-config-$(date +%Y%m%d-%H%M%S)"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

echo "Retrieving storage configuration from ${REMOTE_USER}@${REMOTE_SERVER}..."
mkdir -p "$BACKUP_DIR"

# Get comprehensive storage information
log "Gathering storage information..."
ssh -t "${REMOTE_USER}@${REMOTE_SERVER}" "
    echo '=== Storage Configuration Analysis ===' > /tmp/storage_info.txt
    echo 'Generated: \$(date)' >> /tmp/storage_info.txt
    echo 'Server: ${REMOTE_SERVER}' >> /tmp/storage_info.txt
    echo '' >> /tmp/storage_info.txt
    
    echo '=== Disk Usage ===' >> /tmp/storage_info.txt
    df -h >> /tmp/storage_info.txt
    echo '' >> /tmp/storage_info.txt
    
    echo '=== Block Devices ===' >> /tmp/storage_info.txt
    lsblk -f >> /tmp/storage_info.txt
    echo '' >> /tmp/storage_info.txt
    
    echo '=== Mount Points ===' >> /tmp/storage_info.txt
    mount | grep -E '^/dev/' >> /tmp/storage_info.txt
    echo '' >> /tmp/storage_info.txt
    
    echo '=== File System Table ===' >> /tmp/storage_info.txt
    sudo cat /etc/fstab >> /tmp/storage_info.txt
    echo '' >> /tmp/storage_info.txt
    
    echo '=== Volume UUIDs ===' >> /tmp/storage_info.txt
    sudo blkid >> /tmp/storage_info.txt
    echo '' >> /tmp/storage_info.txt
    
    echo '=== Directory Structure of Web Volume ===' >> /tmp/storage_info.txt
    ls -la /var/www/jxqz.org/ | head -20 >> /tmp/storage_info.txt
    echo '' >> /tmp/storage_info.txt
    
    echo '=== Web Volume Size Breakdown ===' >> /tmp/storage_info.txt
    du -sh /var/www/jxqz.org/* 2>/dev/null | sort -hr | head -10 >> /tmp/storage_info.txt
    echo '' >> /tmp/storage_info.txt
    
    echo '=== File System Information ===' >> /tmp/storage_info.txt
    sudo tune2fs -l /dev/vdb1 | grep -E 'Filesystem|Block|Inode|Mount' >> /tmp/storage_info.txt 2>/dev/null || echo 'Could not get filesystem details' >> /tmp/storage_info.txt
"

# Retrieve the storage information
scp "${REMOTE_USER}@${REMOTE_SERVER}:/tmp/storage_info.txt" "$BACKUP_DIR/STORAGE_ANALYSIS.txt" 2>/dev/null
ssh "${REMOTE_USER}@${REMOTE_SERVER}" "rm -f /tmp/storage_info.txt"

# Create storage documentation
cat > "$BACKUP_DIR/STORAGE_DOCUMENTATION.md" << 'EOF'
# Production Storage Configuration

## Overview
This documents the storage configuration of the production JXQZ server for Infrastructure as Code recreation.

## Storage Layout

### Primary Disk (vda)
- **Device:** `/dev/vda1`
- **Size:** 10GB
- **Mount:** `/` (root filesystem)
- **Purpose:** Operating system, applications, configurations
- **Filesystem:** ext4

### Additional Volume (vdb) 
- **Device:** `/dev/vdb1`
- **Size:** 40GB  
- **Mount:** `/var/www/jxqz.org`
- **Purpose:** Web content, image galleries, user data
- **Filesystem:** ext4
- **Options:** `defaults,noatime,nofail`

## Benefits of This Configuration

### 1. **Data Separation**
- OS and web content on separate volumes
- Web data persists through OS reinstalls
- Different backup strategies for OS vs. data

### 2. **Performance Optimization**
- `noatime` option reduces disk I/O for web volume
- Large image galleries don't affect OS performance
- Can optimize each volume differently

### 3. **Scalability**
- Web volume can be resized independently
- Easy to migrate web content to larger storage
- OS volume stays lean and fast

### 4. **Disaster Recovery**
- Can snapshot web volume separately
- Faster OS recovery (smaller volume)
- Web content is self-contained

## Infrastructure as Code Implications

### Terraform Considerations
1. **Volume Creation:** Need to create and attach additional volume
2. **Formatting:** Must format new volume with ext4
3. **Mounting:** Configure fstab entry for persistent mounting
4. **Permissions:** Set proper ownership for web content

### VirtualBox Testing
- Mock additional volume with host folder or second disk
- Test mount configurations and permissions
- Validate web content deployment to correct location

### Backup Strategy
- **OS Volume:** Configuration and package state
- **Web Volume:** All galleries, user content, uploaded files
- **Database:** Separate backup of PostgreSQL data

## Mount Configuration Details

### fstab Entry
```
/dev/vdb1   /var/www/jxqz.org   ext4   defaults,noatime,nofail   0   0
```

### Mount Options Explained
- **defaults:** Standard mount options (rw, suid, dev, exec, auto, nouser, async)
- **noatime:** Don't update access times (performance optimization)
- **nofail:** Boot continues if volume fails to mount

### Directory Structure
The web volume contains:
- Gallery directories (organized by location/theme)
- Static web content
- User-uploaded content
- Application assets

## Recovery Procedures

### Complete Recovery
1. Create new VM with primary disk
2. Create and attach additional 40GB volume
3. Format additional volume: `mkfs.ext4 /dev/vdb1`
4. Create mount point: `mkdir -p /var/www/jxqz.org`
5. Add fstab entry
6. Mount volume: `mount /var/www/jxqz.org`
7. Restore web content from backup
8. Set permissions: `chown -R steve:www-data /var/www/jxqz.org`

### Partial Recovery (Web Content Only)
1. Mount existing web volume to new server
2. Verify fstab configuration
3. Restart web services

## Monitoring and Maintenance

### Regular Checks
- Monitor disk usage: `df -h`
- Check filesystem health: `fsck -n /dev/vdb1`
- Verify mount options: `mount | grep vdb1`

### Expansion Procedures
1. Resize volume at provider level
2. Resize filesystem: `resize2fs /dev/vdb1`
3. Verify new size: `df -h /var/www/jxqz.org`

EOF

# Create Terraform variable suggestions
cat > "$BACKUP_DIR/terraform-storage-vars.tf" << 'EOF'
# Storage configuration variables for production recreation

variable "enable_additional_storage" {
  description = "Create additional storage volume for web content"
  type        = bool
  default     = true
}

variable "web_volume_size" {
  description = "Size of web content volume in GB"
  type        = number
  default     = 40
}

variable "web_volume_mount" {
  description = "Mount point for web content volume"
  type        = string
  default     = "/var/www/jxqz.org"
}

variable "web_volume_filesystem" {
  description = "Filesystem type for web volume"
  type        = string
  default     = "ext4"
}

variable "web_volume_options" {
  description = "Mount options for web volume"
  type        = string
  default     = "defaults,noatime,nofail"
}

# Local configuration for storage
locals {
  storage_config = {
    production = {
      primary_disk_size    = 10  # GB
      web_volume_size     = var.web_volume_size
      web_mount_point     = var.web_volume_mount
      web_filesystem      = var.web_volume_filesystem
      web_mount_options   = var.web_volume_options
    }
    
    virtualbox = {
      # For testing, simulate with host directory or second disk
      primary_disk_size    = 10  # GB  
      web_volume_size     = 5    # Smaller for testing
      web_mount_point     = var.web_volume_mount
      web_filesystem      = var.web_volume_filesystem
      web_mount_options   = "defaults,noatime"  # Remove nofail for testing
    }
  }
}
EOF

log "✅ Storage configuration documentation completed!"
log "📁 Location: $BACKUP_DIR"
log "📄 Analysis: $BACKUP_DIR/STORAGE_ANALYSIS.txt"
log "📚 Documentation: $BACKUP_DIR/STORAGE_DOCUMENTATION.md" 
log "🏗️  Terraform vars: $BACKUP_DIR/terraform-storage-vars.tf"
log ""
log "🔧 Next Steps:"
log "   1. Review storage analysis and documentation"
log "   2. Update Terraform modules to handle additional volume"
log "   3. Update VirtualBox configuration for storage testing"
log "   4. Test storage configuration in VM before production changes"