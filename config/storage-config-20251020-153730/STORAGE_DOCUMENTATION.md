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

