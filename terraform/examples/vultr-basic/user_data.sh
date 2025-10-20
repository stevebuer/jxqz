#!/bin/bash

#
# User data script for JXQZ web server initial setup
# This runs when the server first boots
#

set -euo pipefail

# Log everything
exec > >(tee /var/log/user-data.log)
exec 2>&1

echo "Starting JXQZ server setup at $(date)"

# Update system
apt-get update
apt-get upgrade -y

# Install essential packages
apt-get install -y \
    apache2 \
    imagemagick \
    rsync \
    git \
    vim \
    htop \
    ufw \
    certbot \
    python3-certbot-apache

# Configure UFW firewall
ufw --force enable
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp

# Enable Apache modules
a2enmod rewrite
a2enmod userdir
a2enmod ssl

# Create steve user (matching your local setup)
useradd -m -s /bin/bash steve
usermod -aG sudo steve

# Set up steve's public_html directory
mkdir -p /home/steve/public_html
chown steve:steve /home/steve/public_html
chmod 755 /home/steve/public_html

# Basic Apache virtual host for ${domain_name}
cat > /etc/apache2/sites-available/${domain_name}.conf << 'EOF'
<VirtualHost *:80>
    ServerName ${domain_name}
    ServerAlias www.${domain_name}
    DocumentRoot /var/www/${domain_name}
    
    <Directory /var/www/${domain_name}>
        AllowOverride All
        Require all granted
    </Directory>
    
    ErrorLog $${APACHE_LOG_DIR}/${domain_name}_error.log
    CustomLog $${APACHE_LOG_DIR}/${domain_name}_access.log combined
</VirtualHost>
EOF

# Create document root
mkdir -p /var/www/${domain_name}
chown www-data:www-data /var/www/${domain_name}

# Create a basic index page
cat > /var/www/${domain_name}/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>${domain_name}</title>
</head>
<body>
    <h1>Welcome to ${domain_name}</h1>
    <p>Server provisioned with Terraform at $(date)</p>
    <p>Ready for content deployment!</p>
</body>
</html>
EOF

# Enable the site
a2ensite ${domain_name}
a2dissite 000-default

# Restart Apache
systemctl restart apache2
systemctl enable apache2

# Create deployment directory structure
mkdir -p /opt/jxqz/{scripts,backups,logs}
chown -R steve:steve /opt/jxqz

# Install jxqz scripts (placeholder - you'll deploy these via rsync)
cat > /opt/jxqz/scripts/deploy.sh << 'EOF'
#!/bin/bash
# Deployment script placeholder
# This will be replaced by your actual deployment process
echo "JXQZ deployment script ready"
EOF

chmod +x /opt/jxqz/scripts/deploy.sh

# Set up automatic security updates
echo 'Unattended-Upgrade::Automatic-Reboot "false";' >> /etc/apt/apt.conf.d/50unattended-upgrades
systemctl enable unattended-upgrades

# Create a status file
cat > /var/log/jxqz-setup-complete << EOF
JXQZ Server Setup Complete
=========================
Date: $(date)
Hostname: $(hostname)
IP: $(curl -s ifconfig.me)
Apache: $(apache2 -v | head -1)
ImageMagick: $(convert -version | head -1)

Next steps:
1. Point DNS to this server
2. Deploy content via rsync
3. Set up SSL with: certbot --apache -d ${domain_name}
4. Configure backup strategy
EOF

echo "JXQZ server setup completed successfully at $(date)"