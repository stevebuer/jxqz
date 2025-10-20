# JXQZ Storage Configuration - Current vs Enhanced

## Overview

This document outlines the current storage configuration and the planned enhanced storage layout that consolidates all web content onto a dedicated storage volume.

## Current Production Configuration

### Mount Points
- **Primary Disk (10GB):** `/` - OS, applications, configs, databases, user home directories
- **Web Volume (40GB):** `/var/www/jxqz.org` - Main website content only

### Directory Layout
```
/                           # Primary disk (10GB, 86% full)
├── var/www/
│   ├── jxqz.org/          # ➡️  SYMLINK to /var/www/jxqz.org (web volume)
│   ├── dx.jxqz.org/       # On primary disk
│   ├── arpoison.net/      # On primary disk  
│   └── suoc.org/          # On primary disk
└── home/steve/
    └── public_html/       # On primary disk (user development content)

/var/www/jxqz.org/         # Web volume (40GB, 20% used)
├── film/                  # 2.6GB
├── foreign/               # 1.7GB
├── cascadia/              # 1.7GB
└── [other galleries]      # ~2GB
```

### Current Issues
1. **Split Web Content:** Main site on volume, other sites on primary disk
2. **Space Constraints:** Primary disk 86% full, limiting user content
3. **Backup Complexity:** Web content spread across two locations
4. **Performance Inconsistency:** User content on slower primary disk

## Enhanced Storage Configuration (Planned)

### Mount Points
- **Primary Disk (10GB):** `/` - OS, applications, configs only
- **Web Volume (40GB):** `/web-content` - ALL web-related content

### Directory Layout
```
/                           # Primary disk (OS only)
├── var/www/               # Contains compatibility symlinks
│   ├── jxqz.org/         # ➡️  SYMLINK to /web-content/sites/jxqz.org
│   ├── dx.jxqz.org/      # ➡️  SYMLINK to /web-content/sites/dx.jxqz.org
│   ├── arpoison.net/     # ➡️  SYMLINK to /web-content/sites/arpoison.net
│   └── suoc.org/         # ➡️  SYMLINK to /web-content/sites/suoc.org
└── home/steve/
    └── public_html/       # ➡️  SYMLINK to /web-content/user/steve/public_html

/web-content/               # Web volume (40GB, dedicated for all web content)
├── sites/                 # Main website content
│   ├── jxqz.org/         # Photo galleries (existing content moved here)
│   ├── dx.jxqz.org/      # Flask analytics application
│   ├── arpoison.net/     # Additional domain content
│   └── suoc.org/         # Additional domain content
├── user/                  # User development content
│   └── steve/
│       └── public_html/  # User development area (moved from home)
├── backups/              # Local backup staging area
├── uploads/              # Temporary upload area
└── logs/                 # Web-specific logs (optional)
```

### Enhanced Benefits

#### 1. **Unified Web Storage**
- All web content on dedicated, high-performance volume
- Consistent backup strategy for all web assets
- Single mount point for all web-related data

#### 2. **Improved Performance**
- User content benefits from `noatime` mount option
- All web content on optimized storage volume
- Reduced I/O pressure on primary disk

#### 3. **Better Scalability**
- Can expand web volume independent of OS disk
- All web content grows together on same volume
- Easier to migrate or upgrade storage

#### 4. **Simplified Operations**
- One backup location for all web content
- Consistent permissions across all web assets
- Easier disaster recovery procedures

#### 5. **Development Benefits**
- More space for user development content
- Consistent performance for gallery generation
- Better isolation of web content from system

## Migration Strategy

### Phase 1: Preparation & Testing (Current)
- [x] Document current configuration
- [x] Plan enhanced storage layout
- [x] Update VirtualBox configuration for testing
- [x] Create migration scripts and procedures
- [ ] Test migration in VirtualBox environment
- [ ] Validate all functionality with new layout

### Phase 2: Production Migration (Planned)
- [ ] Schedule maintenance window (estimate 30-60 minutes)
- [ ] Create full backup of current system
- [ ] Stop web services (Apache, applications)
- [ ] Create new directory structure on web volume
- [ ] Move all web content to new locations
- [ ] Update Apache virtual host configurations
- [ ] Create compatibility symlinks
- [ ] Test all functionality
- [ ] Restart services and validate

### Phase 3: Optimization (Post-Migration)
- [ ] Monitor performance and verify benefits
- [ ] Update backup procedures for single location
- [ ] Update documentation and scripts
- [ ] Clean up old content after validation period

## Apache Configuration Changes

### Current UserDir Configuration
```apache
UserDir public_html
<Directory "/home/*/public_html">
    AllowOverride All
    Options MultiViews Indexes SymLinksIfOwnerMatch
</Directory>
```

### Enhanced UserDir Configuration
```apache
UserDir /web-content/user/*/public_html
<Directory "/web-content/user/*/public_html">
    AllowOverride All
    Options MultiViews Indexes SymLinksIfOwnerMatch
</Directory>
```

### Virtual Host Updates
All virtual hosts will use document roots under `/web-content/sites/` instead of `/var/www/`.

## fstab Changes

### Current
```
UUID=13b2195c-fdd8-4723-b805-cf2265854f74 /               ext4    errors=remount-ro 0       1
UUID=850eaf34-7eed-4b48-9adf-947fe8298704 /var/www/jxqz.org ext4 defaults,noatime,nofail 0 0
```

### Enhanced
```
UUID=13b2195c-fdd8-4723-b805-cf2265854f74 /               ext4    errors=remount-ro 0       1
UUID=850eaf34-7eed-4b48-9adf-947fe8298704 /web-content   ext4    defaults,noatime,nofail 0 0
```

## Testing Environment

The VirtualBox testing environment has been updated to support both storage layouts:

- **Enhanced Layout:** Creates `/web-content` mount with full directory structure
- **Compatibility:** Maintains symlinks for backward compatibility
- **Testing:** Validates all functionality works with new layout

## Rollback Plan

If issues arise during migration:

1. **Stop services** (Apache, etc.)
2. **Remove symlinks**
3. **Move content back** to original locations
4. **Restore original** Apache configuration
5. **Update fstab** back to current configuration
6. **Restart services** and verify functionality

## Implementation Files

### Created Scripts
- `plan-enhanced-storage.sh` - Comprehensive planning and documentation
- `test-enhanced-storage.sh` - VirtualBox testing validation
- `enhanced-storage.tf` - Terraform configuration for new layout

### Updated Files
- `Vagrantfile` - Enhanced storage simulation in VirtualBox
- `vm-test.sh` - Status reporting for enhanced storage layout

### Documentation
- `ENHANCED_STORAGE_PLAN.md` - Detailed migration plan
- `MIGRATION_CHECKLIST.md` - Step-by-step migration checklist

## Next Steps

1. **Test in VirtualBox:** Run enhanced storage tests to validate configuration
2. **Gallery Script Testing:** Ensure gallery generation works with new layout
3. **Performance Validation:** Verify no performance degradation
4. **Production Planning:** Schedule maintenance window for migration
5. **Backup Strategy:** Update backup procedures for single web content location

## Storage Usage Projections

### Current Usage
- Primary disk: 10GB (86% full) - Need to reduce
- Web volume: 40GB (20% used) - Plenty of space for all web content

### After Migration
- Primary disk: 10GB (60-70% expected) - OS and applications only
- Web volume: 40GB (25-30% expected) - All web content consolidated

This migration will free up significant space on the primary disk while consolidating all web-related content for better management and performance.