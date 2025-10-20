#!/bin/bash

#
# plan-enhanced-storage.sh - Plan consolidated web content storage
# Documents strategy for moving all web content to dedicated volume
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="./enhanced-storage-plan-$(date +%Y%m%d-%H%M%S)"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

echo "Creating enhanced storage configuration plan..."
mkdir -p "$BACKUP_DIR"

# Create comprehensive storage plan
cat > "$BACKUP_DIR/ENHANCED_STORAGE_PLAN.md" << 'EOF'
# Enhanced Storage Configuration Plan

## Current State Analysis

### Current Mount Points
- **Primary Disk (vda1):** `/` - OS, applications, configs, databases
- **Web Volume (vdb1):** `/var/www/jxqz.org` - Main website content only
- **User Content:** `/home/steve/public_html` - On primary disk (limited space)

### Current Limitations
1. **Split Web Content:** Main site on volume, user content on primary disk
2. **Backup Complexity:** Web content spread across two locations
3. **Space Constraints:** User content limited by primary disk space (86% full)
4. **Inconsistent Performance:** User content on slower primary disk

## Proposed Enhanced Configuration

### New Mount Strategy
- **Primary Disk (vda1):** `/` - OS, applications, configs only
- **Web Volume (vdb1):** `/web-content` - ALL web-related content
- **User Content:** Moved to web volume via symlinks

### Directory Structure on Web Volume
```
/web-content/
├── sites/
│   ├── jxqz.org/          # Main website (current /var/www/jxqz.org)
│   ├── dx.jxqz.org/       # Analytics application
│   ├── arpoison.net/      # Additional domain
│   └── suoc.org/          # Additional domain
├── user/
│   └── steve/
│       └── public_html/   # User development content (current ~/public_html)
├── backups/               # Local backup staging area
├── uploads/               # Temporary upload area
└── logs/                  # Web-specific logs (optional)
```

### Apache Virtual Host Updates
```apache
# jxqz.org
DocumentRoot /web-content/sites/jxqz.org

# dx.jxqz.org  
DocumentRoot /web-content/sites/dx.jxqz.org/public_html

# User directory
UserDir /web-content/user/*/public_html
```

### Symlink Strategy
```bash
# Maintain compatibility with existing paths
ln -sf /web-content/sites/jxqz.org /var/www/jxqz.org
ln -sf /web-content/sites/dx.jxqz.org /var/www/dx.jxqz.org
ln -sf /web-content/sites/arpoison.net /var/www/arpoison.net
ln -sf /web-content/sites/suoc.org /var/www/suoc.org

# User directory compatibility
ln -sf /web-content/user/steve/public_html /home/steve/public_html
```

## Migration Benefits

### 1. **Unified Web Storage**
- All web content on dedicated, high-performance volume
- Consistent backup strategy for all web assets
- Single mount point for all web-related data

### 2. **Improved Performance**
- User content gets benefit of noatime mount option
- All web content on optimized storage volume
- Reduced I/O pressure on primary disk

### 3. **Better Scalability**
- Can expand web volume independent of OS disk
- All web content grows together on same volume
- Easier to migrate or upgrade storage

### 4. **Simplified Operations**
- One backup location for all web content
- Consistent permissions across all web assets
- Easier disaster recovery procedures

### 5. **Development Benefits**
- More space for user development content
- Consistent performance for gallery generation
- Better isolation of web content from system

## Migration Strategy

### Phase 1: Preparation
1. **Plan Downtime:** Brief maintenance window needed
2. **Backup Current State:** Full backup of both locations
3. **Test in VirtualBox:** Validate migration procedure
4. **Update Terraform:** Modify configurations for new layout

### Phase 2: Migration (During Maintenance Window)
1. **Stop Services:** Apache, any web-related services
2. **Create New Structure:** Build directory layout on web volume
3. **Move Content:** Transfer all web content to new locations
4. **Update Configurations:** Apache, user settings, etc.
5. **Create Symlinks:** Maintain compatibility with old paths
6. **Test Everything:** Verify all sites and functionality
7. **Restart Services:** Bring everything back online

### Phase 3: Cleanup and Optimization
1. **Monitor Performance:** Ensure everything works correctly
2. **Update Documentation:** Reflect new storage layout
3. **Update Backup Scripts:** Single location backup
4. **Clean Old Paths:** Remove original content after validation

## Risk Mitigation

### Rollback Plan
1. **Keep Original Data:** Don't delete until migration verified
2. **Quick Rollback:** Can revert symlinks if issues arise
3. **Service Recovery:** Standard service restart procedures

### Testing Strategy
1. **VirtualBox Testing:** Full migration simulation
2. **Terraform Validation:** Infrastructure as Code testing
3. **Gallery Script Testing:** Ensure scripts work with new layout
4. **Performance Testing:** Verify no performance degradation

## Implementation Timeline

### Immediate (Development)
- [ ] Update VirtualBox configuration for testing
- [ ] Modify Terraform for new storage layout
- [ ] Test migration procedure in VM
- [ ] Update documentation and scripts

### Near-term (Production)
- [ ] Schedule maintenance window
- [ ] Perform full backup
- [ ] Execute migration plan
- [ ] Validate all functionality
- [ ] Update monitoring and backup procedures

## New fstab Configuration
```
# Enhanced storage configuration
UUID=13b2195c-fdd8-4723-b805-cf2265854f74 /               ext4    errors=remount-ro 0       1
UUID=850eaf34-7eed-4b48-9adf-947fe8298704 /web-content   ext4    defaults,noatime,nofail 0       0
```

## Apache Configuration Updates

### UserDir Module Configuration
```apache
# /etc/apache2/mods-enabled/userdir.conf
<IfModule mod_userdir.c>
    UserDir /web-content/user/*/public_html
    UserDir disabled root
    
    <Directory "/web-content/user/*/public_html">
        AllowOverride All
        Options MultiViews Indexes SymLinksIfOwnerMatch
        <Limit GET POST OPTIONS>
            Require all granted
        </Limit>
        <LimitExcept GET POST OPTIONS>
            Require valid-user
        </LimitExcept>
    </Directory>
</IfModule>
```

### Virtual Host Template
```apache
<VirtualHost *:80>
    ServerName {domain}
    DocumentRoot /web-content/sites/{domain}
    
    <Directory /web-content/sites/{domain}>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    
    ErrorLog ${APACHE_LOG_DIR}/{domain}-error.log
    CustomLog ${APACHE_LOG_DIR}/{domain}-access.log combined
</VirtualHost>
```

## Terraform Variables for Enhanced Storage

```hcl
variable "web_volume_mount_point" {
  description = "Mount point for consolidated web content volume"
  type        = string
  default     = "/web-content"
}

variable "maintain_compatibility_symlinks" {
  description = "Create symlinks for backward compatibility"
  type        = bool
  default     = true
}

locals {
  web_paths = {
    volume_mount    = var.web_volume_mount_point
    sites_dir      = "${var.web_volume_mount_point}/sites"
    user_dir       = "${var.web_volume_mount_point}/user"
    backup_dir     = "${var.web_volume_mount_point}/backups"
    
    # Site-specific paths
    jxqz_path      = "${var.web_volume_mount_point}/sites/jxqz.org"
    dx_path        = "${var.web_volume_mount_point}/sites/dx.jxqz.org"
    arpoison_path  = "${var.web_volume_mount_point}/sites/arpoison.net"
    suoc_path      = "${var.web_volume_mount_point}/sites/suoc.org"
    
    # User paths
    steve_public   = "${var.web_volume_mount_point}/user/steve/public_html"
  }
}
```

## Monitoring and Alerting

### Disk Space Monitoring
- Monitor `/web-content` volume usage
- Alert when usage exceeds 80%
- Track growth trends for capacity planning

### Performance Monitoring
- Monitor I/O performance on web volume
- Track Apache response times
- Monitor user directory access patterns

### Backup Verification
- Verify single backup location covers all web content
- Test restore procedures for new layout
- Validate symlink preservation in backups

EOF

# Create migration checklist
cat > "$BACKUP_DIR/MIGRATION_CHECKLIST.md" << 'EOF'
# Storage Migration Checklist

## Pre-Migration (VirtualBox Testing)
- [ ] Test enhanced storage configuration in VM
- [ ] Validate all symlinks work correctly
- [ ] Test Apache configuration changes
- [ ] Verify gallery scripts work with new layout
- [ ] Test user directory functionality
- [ ] Validate backup and restore procedures

## Production Migration Preparation
- [ ] Schedule maintenance window (estimate 30-60 minutes)
- [ ] Notify users of planned downtime
- [ ] Create full backup of current system
- [ ] Prepare rollback procedures
- [ ] Stage new configuration files

## Migration Execution
- [ ] Stop web services (Apache, any web apps)
- [ ] Create new directory structure on web volume
- [ ] Move jxqz.org content to new location
- [ ] Move dx.jxqz.org content to new location  
- [ ] Move other domain content to new location
- [ ] Move ~/public_html to new user directory
- [ ] Update Apache virtual host configurations
- [ ] Update UserDir configuration
- [ ] Create compatibility symlinks
- [ ] Update fstab if changing mount point
- [ ] Set proper permissions on all moved content
- [ ] Test Apache configuration syntax
- [ ] Start Apache and test basic functionality
- [ ] Test all domains and user directory
- [ ] Verify gallery generation still works
- [ ] Check logs for any errors

## Post-Migration Validation
- [ ] Test all websites load correctly
- [ ] Verify user directory access works
- [ ] Test gallery script functionality
- [ ] Check file permissions are correct
- [ ] Monitor system performance
- [ ] Verify backup procedures work with new layout
- [ ] Update documentation
- [ ] Clean up old content after validation period

## Rollback Procedures (if needed)
- [ ] Stop Apache
- [ ] Remove symlinks
- [ ] Move content back to original locations
- [ ] Restore original Apache configuration
- [ ] Restart Apache
- [ ] Verify functionality restored
EOF

# Create Terraform configuration for enhanced storage
cat > "$BACKUP_DIR/enhanced-storage.tf" << 'EOF'
# Enhanced storage configuration with consolidated web content

# Storage configuration variables
variable "enhanced_storage_layout" {
  description = "Use enhanced storage layout with consolidated web content"
  type        = bool
  default     = false  # Set to true when ready to migrate
}

variable "web_content_mount" {
  description = "Mount point for consolidated web content"
  type        = string
  default     = "/web-content"
}

# Enhanced storage paths
locals {
  storage_layout = var.enhanced_storage_layout ? {
    # Enhanced layout - all web content on dedicated volume
    web_volume_mount = var.web_content_mount
    jxqz_document_root = "${var.web_content_mount}/sites/jxqz.org"
    dx_document_root = "${var.web_content_mount}/sites/dx.jxqz.org/public_html"
    arpoison_document_root = "${var.web_content_mount}/sites/arpoison.net"
    suoc_document_root = "${var.web_content_mount}/sites/suoc.org"
    user_dir_path = "${var.web_content_mount}/user/*/public_html"
    steve_public_html = "${var.web_content_mount}/user/steve/public_html"
    
    # Compatibility symlinks
    create_symlinks = true
    symlink_targets = {
      "/var/www/jxqz.org" = "${var.web_content_mount}/sites/jxqz.org"
      "/var/www/dx.jxqz.org" = "${var.web_content_mount}/sites/dx.jxqz.org"
      "/var/www/arpoison.net" = "${var.web_content_mount}/sites/arpoison.net"
      "/var/www/suoc.org" = "${var.web_content_mount}/sites/suoc.org"
      "/home/steve/public_html" = "${var.web_content_mount}/user/steve/public_html"
    }
  } : {
    # Current layout - keep existing configuration
    web_volume_mount = "/var/www/jxqz.org"
    jxqz_document_root = "/var/www/jxqz.org"
    dx_document_root = "/var/www/dx.jxqz.org/public_html"
    arpoison_document_root = "/var/www/arpoison.net"
    suoc_document_root = "/var/www/suoc.org"
    user_dir_path = "/home/*/public_html"
    steve_public_html = "/home/steve/public_html"
    
    create_symlinks = false
    symlink_targets = {}
  }
}

# Output storage configuration for reference
output "storage_configuration" {
  value = {
    layout_type = var.enhanced_storage_layout ? "enhanced" : "current"
    mount_point = local.storage_layout.web_volume_mount
    document_roots = {
      jxqz = local.storage_layout.jxqz_document_root
      dx = local.storage_layout.dx_document_root
      arpoison = local.storage_layout.arpoison_document_root
      suoc = local.storage_layout.suoc_document_root
    }
    user_directory = local.storage_layout.user_dir_path
    symlinks_enabled = local.storage_layout.create_symlinks
  }
}
EOF

log "✅ Enhanced storage plan created successfully!"
log "📁 Location: $BACKUP_DIR"
log "📋 Migration Plan: $BACKUP_DIR/ENHANCED_STORAGE_PLAN.md"
log "✅ Checklist: $BACKUP_DIR/MIGRATION_CHECKLIST.md"
log "🏗️  Terraform Config: $BACKUP_DIR/enhanced-storage.tf"
log ""
log "🔧 Next Steps:"
log "   1. Review the enhanced storage plan"
log "   2. Update VirtualBox configuration for testing"
log "   3. Test migration procedure in VM"
log "   4. Plan production migration timeline"
log ""
log "💡 Key Benefits:"
log "   - All web content on dedicated volume (/web-content)"
log "   - User content gets performance benefits"
log "   - Simplified backup strategy"
log "   - Better scalability and organization"