# Production Web Content Mirror & Backup Strategy

## 🚨 CRITICAL PRIORITY: Immediate Backup

Your concern is 100% valid - having production as the only copy is extremely risky. This needs immediate attention before any infrastructure changes.

## Quick Start (Immediate Action)

### 1. Run the Mirror Script
```bash
# Edit the script first to set your server details
nano mirror-production-web.sh

# Then run the mirror
./mirror-production-web.sh your-server-ip-or-domain
```

### 2. What Gets Mirrored
- ✅ **All web content** (`/var/www/`, `~/public_html/`)
- ✅ **Database backups** (PostgreSQL dumps)  
- ✅ **Server configuration** (Apache, SSL, Dovecot)
- ✅ **User settings** (crontabs, shell configs)

### 3. Mirror Location
- **Local path**: `/home/steve/PRODUCTION_MIRROR/YYYY-MM-DD_HH-MM-SS/`
- **Timestamped**: Each mirror is date-stamped for history
- **Organized**: Separate folders for web content, databases, config

## Advanced Mirroring Options

### Option 1: Selective Content Mirror (Faster)
```bash
# Quick web content only (excludes databases/config)
rsync -avz --progress steve@your-server:/var/www/ ~/PRODUCTION_MIRROR/web-content/
rsync -avz --progress steve@your-server:~/public_html/ ~/PRODUCTION_MIRROR/user-web/
```

### Option 2: Complete System Backup
```bash
# Full server backup (requires root access or sudo)
rsync -avz --progress --exclude='/proc/*' --exclude='/sys/*' --exclude='/dev/*' \
  steve@your-server:/ ~/PRODUCTION_MIRROR/full-system/
```

### Option 3: Database-Only Backup
```bash
# PostgreSQL only
ssh steve@your-server "sudo -u postgres pg_dumpall" > ~/PRODUCTION_MIRROR/all-databases.sql
```

## Development Environment Setup

### After Mirroring
1. **Review content**: Check `MIRROR_REPORT.md`
2. **Set up local web server**: Apache/Nginx pointing to mirrored content
3. **Import databases**: Load SQL dumps into local PostgreSQL
4. **Create git repository**: Version control for ongoing development
5. **Adapt configuration**: Modify configs for local development

### Local Development Stack
```bash
# Example local setup
mkdir -p ~/DEV_ENVIRONMENT
cp -r ~/PRODUCTION_MIRROR/latest/web-content/* ~/DEV_ENVIRONMENT/
# Configure local Apache to serve from ~/DEV_ENVIRONMENT
```

## Ongoing Backup Strategy

### Automated Daily Backup
Create a cron job to run daily mirrors:
```bash
# Add to crontab
0 2 * * * /home/steve/GITHUB/jxqz/mirror-production-web.sh your-server >/dev/null 2>&1
```

### Git-Based Backup
```bash
# Initialize git repo for web content
cd ~/PRODUCTION_MIRROR/latest/web-content
git init
git add .
git commit -m "Initial production mirror"
# Push to GitHub/GitLab for off-site backup
```

### Cloud Backup Integration
```bash
# Sync to cloud storage (Google Drive, Dropbox, etc.)
rclone sync ~/PRODUCTION_MIRROR/ googledrive:JXQZ_BACKUPS/
```

## Safety Checklist

### Before Running Mirror
- [ ] Test SSH access to production server
- [ ] Ensure sufficient local disk space (check production size first)
- [ ] Verify production server is stable (not during maintenance)
- [ ] Consider server load impact during business hours

### Security Considerations  
- [ ] Use SSH keys (avoid passwords in scripts)
- [ ] Limit rsync to specific directories
- [ ] Exclude sensitive files (password files, private keys)
- [ ] Set proper permissions on local mirror
- [ ] Consider encryption for sensitive data

### After Mirror Complete
- [ ] Verify mirror integrity (spot-check files)
- [ ] Test database imports locally
- [ ] Document any missing or inaccessible content
- [ ] Set up regular backup schedule
- [ ] Create development environment from mirror

## Emergency Recovery Plan

If production fails:
1. **Web content**: Serve from local mirror immediately
2. **Databases**: Restore from SQL dumps
3. **Configuration**: Apply backed-up configs to new server
4. **DNS**: Update to point to backup/new server

## Integration with Current Infrastructure Plan

### Priority Order
1. **🚨 IMMEDIATE**: Run production mirror (this task)
2. **🚨 URGENT**: Resolve space crisis (can proceed safely after backup)
3. **📋 PLANNED**: Enhanced storage migration (with backup safety net)
4. **🔄 ONGOING**: Infrastructure automation (with backup validation)

### Benefits for Your Infrastructure Work
- **Safety**: Changes can be tested locally first
- **Development**: Local environment for testing new configurations
- **Rollback**: Easy restoration if changes go wrong  
- **Documentation**: Understanding current setup before modernization

---

## Quick Command Reference

```bash
# Check production disk usage first
ssh steve@your-server 'df -h'

# Run complete mirror
./mirror-production-web.sh your-server-address

# Quick web content only
rsync -avz steve@your-server:/var/www/ ~/QUICK_BACKUP/

# Check mirror size
du -sh ~/PRODUCTION_MIRROR/*
```

**⚠️ RECOMMENDED ACTION**: Run the mirror script immediately before any other infrastructure work.