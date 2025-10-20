# Multi-Domain Server Configuration

This example configures a single server to host multiple domains: jxqz.org, dx.jxqz.org (analytics), arpoison.net, and suoc.org.

## What This Creates

- **Single Vultr Server**: 2GB RAM to handle multiple sites + analytics app
- **Apache Virtual Hosts**: Separate configuration for each domain
- **MySQL Database**: Ready for your analytics application
- **PHP Support**: For dynamic content if needed
- **SSL Ready**: Prepared for Let's Encrypt certificates
- **Development Environment**: User directories enabled

## Features

### Multi-Domain Support
- **jxqz.org**: Primary site with image gallery tools and user directory access
- **dx.jxqz.org**: Analytics application (full-stack PHP/MySQL)
- **arpoison.net**: Static content site
- **suoc.org**: Static content site
- **All domains**: Individual Apache virtual hosts with separate logs

### Development Features
- **User Directories**: `~steve/public_html/` accessible via web
- **Deployment Scripts**: Automated deployment for all sites
- **Separate Document Roots**: Clean separation of site content

### Analytics Application Ready
- **MySQL Database**: Pre-configured with analytics database and user
- **PHP Support**: Ready for full-stack applications
- **Security**: Database access restricted to private network

## Cost Efficiency

**Single Server Hosting:**
- **Server**: ~$12/month (2GB RAM, 1 vCPU)
- **Backups**: ~$2.40/month 
- **Total**: ~$15/month for all three domains + analytics

Compare to separate hosting:
- 3 domains × $6/month = $18/month + analytics server
- **Savings**: ~$10-20/month while learning infrastructure skills

## Usage

### Deploy the Server
```bash
cp terraform.tfvars.example terraform.tfvars
# Edit with your API key
terraform init
terraform plan
terraform apply
```

### Configure DNS
Update A records for all domains to point to the server IP:
```
jxqz.org         A    <server-ip>
www.jxqz.org     A    <server-ip>
dx.jxqz.org      A    <server-ip>
arpoison.net     A    <server-ip>
www.arpoison.net A    <server-ip>
suoc.org         A    <server-ip>
www.suoc.org     A    <server-ip>
```

### Deploy Content
```bash
# Create local site directories
mkdir -p ~/sites/{jxqz,dx,arpoison,suoc}

# Deploy each site
rsync -avz ~/sites/jxqz/ steve@<server-ip>:/var/www/jxqz.org/
rsync -avz ~/sites/dx/ steve@<server-ip>:/var/www/dx.jxqz.org/          # Analytics app
rsync -avz ~/sites/arpoison/ steve@<server-ip>:/var/www/arpoison.net/
rsync -avz ~/sites/suoc/ steve@<server-ip>:/var/www/suoc.org/

# Or use the automated deployment script
ssh steve@<server-ip>
sudo /opt/steve/scripts/deploy-all.sh
```

### Set Up SSL
```bash
ssh steve@<server-ip>
sudo certbot --apache -d jxqz.org -d www.jxqz.org
sudo certbot --apache -d dx.jxqz.org                    # Analytics app (no www needed)
sudo certbot --apache -d arpoison.net -d www.arpoison.net
sudo certbot --apache -d suoc.org -d www.suoc.org
```

## Analytics Application Setup

The server includes MySQL and PHP specifically configured for your dx.jxqz.org application:

```bash
# Connect to database
mysql -u analytics -p analytics

# Deploy your analytics application
rsync -avz ~/analytics-app/ steve@<server-ip>:/var/www/dx.jxqz.org/

# Test the application
curl https://dx.jxqz.org/
```

### Application Features
- **Database**: Pre-configured MySQL database named "analytics"
- **PHP Environment**: Error reporting enabled for development
- **API Support**: `/api/` endpoints automatically configured
- **Security**: Basic security headers included
- **SSL Ready**: Prepared for production certificates

## Learning Value

This configuration teaches:

### Infrastructure Concepts
- **Virtual hosts**: Multiple domains on single server
- **Resource sharing**: Efficient use of server resources
- **Security separation**: Isolated document roots
- **Cost optimization**: Multiple services on one server

### DevOps Skills
- **Multi-environment management**: Different sites, same infrastructure
- **Database provisioning**: Automated MySQL setup
- **Deployment automation**: Scripted content deployment
- **SSL management**: Certificate automation with certbot

### Career Applications
- **Real multi-tenant hosting**: Common in production environments
- **Cost-conscious architecture**: Important for small businesses
- **Full-stack deployment**: Database + web server + SSL
- **Maintenance automation**: Deployment and backup scripts

## Monitoring and Maintenance

### Check Site Status
```bash
# Test all domains
curl -H "Host: jxqz.org" http://<server-ip>
curl -H "Host: arpoison.net" http://<server-ip>
curl -H "Host: suoc.org" http://<server-ip>

# Check Apache configuration
sudo apache2ctl configtest

# View logs
sudo tail -f /var/log/apache2/jxqz.org_access.log
sudo tail -f /var/log/apache2/arpoison.net_error.log
```

### Backup Strategy
```bash
# Backup all sites
tar -czf sites-backup-$(date +%Y%m%d).tar.gz /var/www/
mysqldump -u analytics -p analytics > analytics-backup-$(date +%Y%m%d).sql
```

## Scaling Options

As your sites grow:

1. **Vertical Scaling**: Upgrade to larger Vultr plan
2. **CDN Addition**: Add Vultr Object Storage for static assets
3. **Database Separation**: Move analytics DB to separate server
4. **Load Balancing**: Add multiple web servers behind load balancer

This setup gives you a production-ready, cost-effective hosting solution while building valuable DevOps skills that directly apply to your career goals!