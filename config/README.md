# Apache2 Configuration Backup

This directory contains backup copies of Apache2 configuration files for disaster recovery.

## Files to Backup

### Essential Apache2 Configuration
- `apache2.conf` - Main Apache configuration
- `sites-available/` - Virtual host configurations
- `sites-enabled/` - Enabled site symlinks
- `mods-enabled/` - Enabled modules
- `ports.conf` - Port configuration

### Security & SSL
- SSL certificate files (backup separately, not in git)
- `.htaccess` files from web directories

## Recovery Process

1. **Install Apache2** on new Debian system:
   ```bash
   sudo apt update
   sudo apt install apache2
   ```

2. **Stop Apache** before configuration:
   ```bash
   sudo systemctl stop apache2
   ```

3. **Restore configuration files**:
   ```bash
   sudo cp -r config/apache2/* /etc/apache2/
   sudo chown -R root:root /etc/apache2/
   ```

4. **Enable required modules**:
   ```bash
   sudo a2enmod rewrite
   sudo a2enmod userdir  # For ~steve/public_html
   # Add other modules as needed
   ```

5. **Enable sites**:
   ```bash
   sudo a2ensite jxqz.org
   # Enable other sites as configured
   ```

6. **Test configuration**:
   ```bash
   sudo apache2ctl configtest
   ```

7. **Start Apache**:
   ```bash
   sudo systemctl start apache2
   sudo systemctl enable apache2
   ```

## Security Notes

- **DO NOT** commit SSL private keys to git
- Store certificates separately in encrypted backup
- Sanitize configuration files to remove sensitive information before committing
- Consider using environment variables for sensitive values

## Backup Script Example

Create a script to backup current Apache configuration:

```bash
#!/bin/bash
# backup-apache-config.sh

BACKUP_DIR="./config/apache2-backup-$(date +%Y%m%d)"
mkdir -p "$BACKUP_DIR"

# Copy main configuration
sudo cp -r /etc/apache2/* "$BACKUP_DIR/"

# Remove sensitive files
rm -f "$BACKUP_DIR"/ssl/private/*
find "$BACKUP_DIR" -name "*.key" -delete

echo "Apache configuration backed up to $BACKUP_DIR"
echo "Remember to backup SSL certificates separately!"
```

## Recovery Time Objective

Target: **24 hours or less** for complete system recovery including:
- Server provisioning
- Apache installation and configuration
- Content restoration
- DNS updates (if needed)
- SSL certificate installation