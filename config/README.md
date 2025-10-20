# Server Configuration Management

This directory contains tools and backups for server configuration management, disaster recovery, and Infrastructure as Code migration.

## Tools

### `backup-apache-config.sh`
Backs up Apache2 configuration from the local system (must be run on the server with sudo).

### `retrieve-server-configs.sh`
Retrieves comprehensive configuration files from a remote server via SSH. Includes Apache, system configs, SSL certificates, and custom scripts.

**Usage:**
```bash
./retrieve-server-configs.sh -s your-server.com -u steve
```

### `analyze-configs.sh`
Analyzes retrieved configurations to identify customizations and generate recommendations for Terraform module development.

**Usage:**
```bash
./analyze-configs.sh [backup-directory]
```

## Configuration Categories

## Configuration Categories

### Essential Apache2 Configuration
- `apache2.conf` - Main Apache configuration
- `sites-available/` - Virtual host configurations
- `sites-enabled/` - Enabled site symlinks
- `mods-enabled/` - Enabled modules
- `ports.conf` - Port configuration

### System Configuration
- Network settings (`/etc/network/`, `/etc/systemd/network/`)
- Host configuration (`/etc/hostname`, `/etc/hosts`)
- DNS configuration (`/etc/resolv.conf`)

### Service Configuration
- **Dovecot** - IMAP email server configuration
- **Postfix** - SMTP server configuration  
- **fail2ban** - Intrusion prevention
- **UFW** - Uncomplicated Firewall

### Security & SSL
- SSL certificate files (backup separately, not in git)
- Public certificates for documentation
- `.htaccess` files from web directories

### Custom Scripts and Automation
- User scripts (`~/bin/`, `~/scripts/`)
- System scripts (`/usr/local/bin/`, `/opt/`)
- Cron jobs and scheduled tasks

## Workflow

### 1. Retrieve Current Configuration
```bash
# From your local development machine
cd /path/to/jxqz/config
./retrieve-server-configs.sh -s your-server.com

# This creates: server-configs-YYYYMMDD-HHMMSS/
```

### 2. Analyze Retrieved Configuration
```bash
# Analyze what was retrieved
./analyze-configs.sh

# Review the generated analysis report
# Creates: server-configs-*/CONFIGURATION_ANALYSIS.md
```

### 3. Document and Version Control
```bash
# Add to git (sensitive data already sanitized)
git add config/
git commit -m "Add server configuration backup YYYY-MM-DD"
git push
```

### 4. Use for Terraform Development
Use the retrieved configurations and analysis to inform:
- Terraform module development
- Infrastructure as Code migration
- Disaster recovery procedures

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