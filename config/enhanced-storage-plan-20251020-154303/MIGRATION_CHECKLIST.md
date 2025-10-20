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
