#!/bin/bash

#
# Multi-domain server setup script
# Configures Apache for jxqz.org, arpoison.net, suoc.org
#

set -euo pipefail

exec > >(tee /var/log/user-data.log)
exec 2>&1

echo "Starting multi-domain server setup at $(date)"

# Update system
apt-get update
apt-get upgrade -y

# Install packages
apt-get install -y \
    apache2 \
    imagemagick \
    rsync \
    git \
    vim \
    htop \
    ufw \
    certbot \
    python3-certbot-apache \
    mysql-server \
    php \
    php-mysql \
    libapache2-mod-php \
    dovecot-core \
    dovecot-imapd \
    postfix \
    mailutils

# Configure firewall
ufw --force enable
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
# Email ports
ufw allow 143/tcp    # IMAP
ufw allow 993/tcp    # IMAP SSL
ufw allow 587/tcp    # SMTP submission

# Enable Apache modules
a2enmod rewrite
a2enmod userdir
a2enmod ssl
a2enmod php8.2

# Create steve user
useradd -m -s /bin/bash steve
usermod -aG sudo steve

# Set up steve's directories
mkdir -p /home/steve/public_html
chown steve:steve /home/steve/public_html
chmod 755 /home/steve/public_html

# Configure domains from Terraform variable
%{ for domain in domains ~}
echo "Setting up ${domain.name}..."

# Create document root
mkdir -p ${domain.document_root}
chown www-data:www-data ${domain.document_root}

# Create virtual host
cat > /etc/apache2/sites-available/${domain.name}.conf << 'EOF'
<VirtualHost *:80>
    ServerName ${domain.name}
    %{ if domain.name != "dx.jxqz.org" ~}
    ServerAlias www.${domain.name}
    %{ endif ~}
    DocumentRoot ${domain.document_root}
    
    <Directory ${domain.document_root}>
        AllowOverride All
        Require all granted
        Options Indexes FollowSymLinks
        %{ if domain.is_analytics ~}
        # PHP configuration for analytics application
        DirectoryIndex index.php index.html
        %{ endif ~}
    </Directory>
    
    %{ if domain.name == "jxqz.org" ~}
    # Enable user directories for development
    UserDir enabled steve
    UserDir disabled root
    
    <Directory /home/steve/public_html>
        AllowOverride All
        Options Indexes FollowSymLinks
        Require all granted
    </Directory>
    %{ endif ~}
    
    %{ if domain.is_analytics ~}
    # Analytics application specific configuration
    <Directory ${domain.document_root}>
        # Enable PHP error display for development (disable in production)
        php_flag display_errors On
        php_value error_reporting "E_ALL"
        
        # Security headers for web application
        Header always set X-Content-Type-Options nosniff
        Header always set X-Frame-Options DENY
        Header always set X-XSS-Protection "1; mode=block"
    </Directory>
    
    # API endpoint handling
    <LocationMatch "^/api/">
        # Ensure PHP handles API requests
        SetHandler application/x-httpd-php
    </LocationMatch>
    %{ endif ~}
    
    ErrorLog $${APACHE_LOG_DIR}/${domain.name}_error.log
    CustomLog $${APACHE_LOG_DIR}/${domain.name}_access.log combined
</VirtualHost>
EOF

# Create basic index page
%{ if domain.is_analytics ~}
cat > ${domain.document_root}/index.php << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${domain.name} - Analytics Application</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
        .container { max-width: 800px; margin: 0 auto; background: white; padding: 40px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        h1 { color: #333; border-bottom: 2px solid #007bff; padding-bottom: 10px; }
        .status { background: #e3f2fd; padding: 15px; border-radius: 4px; margin: 20px 0; border-left: 4px solid #007bff; }
        .tech-stack { background: #f8f9fa; padding: 15px; border-radius: 4px; margin: 20px 0; }
        .feature-list { margin: 20px 0; }
        .feature-item { background: #fff3cd; padding: 10px; margin: 5px 0; border-left: 4px solid #ffc107; }
        pre { background: #f8f9fa; padding: 15px; border-radius: 4px; overflow-x: auto; }
    </style>
</head>
<body>
    <div class="container">
        <h1>📊 ${domain.name}</h1>
        <h2>Analytics Application Platform</h2>
        
        <div class="status">
            <strong>🚀 Application Status:</strong> Platform ready for deployment<br>
            <strong>📅 Provisioned:</strong> <?php echo date('Y-m-d H:i:s'); ?><br>
            <strong>🔧 Infrastructure:</strong> Terraform + Apache + MySQL + PHP<br>
            <strong>🗄️ Database:</strong> Connected and ready
        </div>
        
        <h2>Technical Stack</h2>
        <div class="tech-stack">
            <strong>Backend:</strong> PHP <?php echo phpversion(); ?><br>
            <strong>Database:</strong> MySQL (analytics database configured)<br>
            <strong>Web Server:</strong> Apache2 with mod_php<br>
            <strong>SSL:</strong> Ready for Let's Encrypt certificates<br>
            <strong>Infrastructure:</strong> Vultr + Terraform (Infrastructure as Code)
        </div>

        <h2>Database Connection Test</h2>
        <div class="status">
        <?php
        try {
            $pdo = new PDO('mysql:host=localhost;dbname=analytics', 'analytics', 'secure_password_change_me');
            echo "✅ <strong>Database Connection:</strong> Successful<br>";
            echo "📊 <strong>Database Name:</strong> analytics<br>";
            echo "🔐 <strong>User:</strong> analytics (configured)";
        } catch (PDOException $e) {
            echo "❌ <strong>Database Connection:</strong> " . $e->getMessage();
        }
        ?>
        </div>

        <h2>Development Features</h2>
        <div class="feature-list">
            <div class="feature-item"><strong>API Ready:</strong> /api/ endpoints configured</div>
            <div class="feature-item"><strong>Error Handling:</strong> PHP error display enabled for development</div>
            <div class="feature-item"><strong>Security Headers:</strong> XSS protection, content type validation</div>
            <div class="feature-item"><strong>SSL Ready:</strong> Prepared for production certificates</div>
        </div>

        <h2>Quick Start</h2>
        <pre><code># Deploy your application
rsync -avz your-analytics-app/ steve@server:/var/www/dx.jxqz.org/

# Set up SSL certificate
certbot --apache -d dx.jxqz.org

# Access application
https://dx.jxqz.org/</code></pre>

        <h2>Database Access</h2>
        <pre><code># Connect to MySQL
mysql -u analytics -p analytics

# PHP PDO Connection
$pdo = new PDO('mysql:host=localhost;dbname=analytics', 'analytics', 'password');</code></pre>

        <p><small><strong>Note:</strong> This is a development status page. Replace with your actual application after deployment.</small></p>
    </div>
</body>
</html>
EOF
%{ else if domain.is_primary ~}
cat > ${domain.document_root}/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${domain.name}</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
        .container { max-width: 800px; margin: 0 auto; background: white; padding: 40px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        h1 { color: #333; border-bottom: 2px solid #ddd; padding-bottom: 10px; }
        .status { background: #e8f5e8; padding: 15px; border-radius: 4px; margin: 20px 0; }
        .domain-list { margin: 20px 0; }
        .domain-item { background: #f8f9fa; padding: 10px; margin: 5px 0; border-left: 4px solid #007bff; }
    </style>
</head>
<body>
    <div class="container">
        <h1>${domain.name}</h1>
        
        <div class="status">
            <strong>✅ Server Status:</strong> Online and configured<br>
            <strong>📅 Deployed:</strong> $(date)<br>
            <strong>🔧 Provisioned:</strong> Terraform Infrastructure as Code
        </div>
        
        <h2>Hosted Domains</h2>
        <div class="domain-list">
            <div class="domain-item"><strong>jxqz.org</strong> - Primary site with image gallery tools</div>
            <div class="domain-item"><strong>dx.jxqz.org</strong> - Analytics application (full-stack database-driven)</div>
            <div class="domain-item"><strong>arpoison.net</strong> - Static content site</div>
            <div class="domain-item"><strong>suoc.org</strong> - Static content site</div>
        </div>
        
        <h2>Development</h2>
        <p><strong>User Directory:</strong> <a href="/~steve/">steve's public_html</a> for development and temporary files</p>
        
        <h2>Next Steps</h2>
        <ul>
            <li>Deploy content via rsync</li>
            <li>Configure SSL certificates with certbot</li>
            <li>Set up analytics database if needed</li>
            <li>Test gallery generation tools</li>
        </ul>
    </div>
</body>
</html>
EOF
%{ else ~}
cat > ${domain.document_root}/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${domain.name}</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; text-align: center; background: #f5f5f5; }
        .container { max-width: 600px; margin: 0 auto; background: white; padding: 40px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        h1 { color: #333; }
        .status { background: #e8f5e8; padding: 15px; border-radius: 4px; margin: 20px 0; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Welcome to ${domain.name}</h1>
        
        <div class="status">
            <strong>Status:</strong> Site configured and ready for content
        </div>
        
        <p>This site is managed alongside jxqz.org on the same server infrastructure.</p>
        <p><small>Deployed: $(date)</small></p>
    </div>
</body>
</html>
EOF
%{ endif ~}

# Enable the site
a2ensite ${domain.name}

%{ endfor ~}

# Disable default site
a2dissite 000-default

# Set up MySQL for analytics application
mysql_secure_installation --use-default

# Create analytics database and user
mysql -e "CREATE DATABASE IF NOT EXISTS analytics;"
mysql -e "CREATE USER IF NOT EXISTS 'analytics'@'localhost' IDENTIFIED BY 'secure_password_change_me';"
mysql -e "GRANT ALL PRIVILEGES ON analytics.* TO 'analytics'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

# Create deployment structure
mkdir -p /opt/steve/{scripts,backups,logs,analytics}
chown -R steve:steve /opt/steve

# Install jxqz gallery scripts
cat > /opt/steve/scripts/deploy-all.sh << 'EOF'
#!/bin/bash
# Multi-domain deployment script

set -euo pipefail

echo "Deploying all sites..."

# Deploy jxqz.org (main site with galleries)
if [[ -d "/home/steve/sites/jxqz" ]]; then
    rsync -av --delete /home/steve/sites/jxqz/ /var/www/jxqz.org/
    echo "✅ jxqz.org deployed"
fi

# Deploy dx.jxqz.org (analytics application)
if [[ -d "/home/steve/sites/dx" ]]; then
    rsync -av --delete /home/steve/sites/dx/ /var/www/dx.jxqz.org/
    echo "✅ dx.jxqz.org (analytics) deployed"
elif [[ -d "/home/steve/analytics" ]]; then
    rsync -av --delete /home/steve/analytics/ /var/www/dx.jxqz.org/
    echo "✅ dx.jxqz.org (analytics from ~/analytics) deployed"
fi

# Deploy arpoison.net
if [[ -d "/home/steve/sites/arpoison" ]]; then
    rsync -av --delete /home/steve/sites/arpoison/ /var/www/arpoison.net/
    echo "✅ arpoison.net deployed"
fi

# Deploy suoc.org
if [[ -d "/home/steve/sites/suoc" ]]; then
    rsync -av --delete /home/steve/sites/suoc/ /var/www/suoc.org/
    echo "✅ suoc.org deployed"
fi

# Set proper permissions
chown -R www-data:www-data /var/www/*/
find /var/www/ -type d -exec chmod 755 {} \;
find /var/www/ -type f -exec chmod 644 {} \;

# Special permissions for analytics app (PHP files need to be executable)
if [[ -d "/var/www/dx.jxqz.org" ]]; then
    find /var/www/dx.jxqz.org -name "*.php" -exec chmod 644 {} \;
    # Make any scripts executable
    find /var/www/dx.jxqz.org -name "*.sh" -exec chmod 755 {} \;
fi

echo "🎉 All sites deployed successfully!"
EOF

chmod +x /opt/steve/scripts/deploy-all.sh

# Restart Apache
systemctl restart apache2
systemctl enable apache2

# Enable MySQL
systemctl enable mysql

# Configure basic email services
# Note: This sets up basic email - you'll need to migrate your existing Dovecot config
systemctl enable dovecot
systemctl enable postfix

# Basic Dovecot configuration for IMAP
cat > /etc/dovecot/conf.d/10-auth.conf << 'EOF'
# Authentication configuration
auth_mechanisms = plain login
disable_plaintext_auth = no  # Will be yes after SSL setup
EOF

cat > /etc/dovecot/conf.d/10-mail.conf << 'EOF'
# Mail location configuration  
mail_location = maildir:~/Maildir
EOF

# Start email services (will need proper configuration)
systemctl start postfix
systemctl start dovecot

# Set up automatic updates
echo 'Unattended-Upgrade::Automatic-Reboot "false";' >> /etc/apt/apt.conf.d/50unattended-upgrades
systemctl enable unattended-upgrades

# Create setup completion status
cat > /var/log/multi-domain-setup-complete << EOF
Multi-Domain Server Setup Complete
==================================
Date: $(date)
Hostname: $(hostname)
IP: $(curl -s ifconfig.me)

Configured Domains:
- jxqz.org (primary site)
- arpoison.net 
- suoc.org

Services:
- Apache: $(apache2 -v | head -1)
- MySQL: $(mysql --version)
- ImageMagick: $(convert -version | head -1)
- PHP: $(php -v | head -1)
- Dovecot: $(dovecot --version)
- Postfix: $(postconf mail_version)

Next Steps:
1. Point all domain DNS to this server IP
2. Deploy content for each domain
3. Set up SSL: certbot --apache -d domain.com
4. Configure analytics application database
5. Test gallery generation tools
6. Migrate existing Dovecot/email configuration
7. Configure MX records for email delivery

Email Configuration:
- IMAP server ready (port 143/993)
- Basic Dovecot installed - needs your existing config
- Postfix installed for SMTP
- Firewall configured for email ports

Useful Commands:
- Deploy all sites: /opt/steve/scripts/deploy-all.sh
- Check Apache status: systemctl status apache2
- View Apache logs: tail -f /var/log/apache2/*.log
- MySQL access: mysql -u analytics -p analytics
EOF

echo "Multi-domain server setup completed at $(date)"