# Basic Vultr Server for JXQZ

This example creates a basic Debian server on Vultr that mirrors your current setup.

## What This Creates

- **Vultr Instance**: Debian 12 server with 1GB RAM, 1 vCPU
- **Firewall Rules**: SSH (22), HTTP (80), HTTPS (443)
- **SSH Key**: Your laptop's public key for access
- **Basic Setup**: Apache2, ImageMagick, user accounts, directory structure

## Prerequisites

1. **Vultr Account**: Sign up at vultr.com
2. **API Key**: Generate in Vultr account settings
3. **SSH Key**: Have `~/.ssh/id_rsa.pub` ready
4. **Terraform**: Installed on your system

## Usage

### Step 1: Configure Variables
```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your Vultr API key
```

### Step 2: Initialize and Plan
```bash
terraform init
terraform plan
```

### Step 3: Deploy
```bash
terraform apply
```

### Step 4: Connect
```bash
# Use the output connection command
ssh root@<server-ip>

# Check setup status
cat /var/log/jxqz-setup-complete
```

## What Happens During Deployment

1. **Server Creation**: Provisions Vultr instance
2. **Security Setup**: Configures firewall and SSH access
3. **Software Installation**: Apache2, ImageMagick, essential tools
4. **User Setup**: Creates 'steve' user with sudo access
5. **Apache Configuration**: Basic virtual host for jxqz.org
6. **Directory Structure**: Sets up deployment directories

## After Deployment

### Deploy Your Content
```bash
# Sync your local content to the new server
rsync -avz --delete /path/to/local/jxqz/ steve@<server-ip>:/var/www/jxqz.org/

# Deploy your scripts
rsync -avz jxqz*.sh steve@<server-ip>:/opt/jxqz/scripts/
```

### Set Up SSL
```bash
ssh steve@<server-ip>
sudo certbot --apache -d jxqz.org -d www.jxqz.org
```

### Update DNS
Point your domain's A record to the new server IP.

## Cost Considerations

- **Basic Server**: ~$6/month (1GB RAM, 1 vCPU)
- **Backups**: ~$1.20/month (20% of server cost)
- **Bandwidth**: Included (1TB/month)

## Scaling Options

Once comfortable with this basic setup:

1. **Larger Server**: Change the plan in `main.tf`
2. **Multiple Servers**: Add load balancer configuration
3. **Database Server**: Add separate instance for your analytics app
4. **CDN**: Add Vultr Object Storage for static assets

## Learning Value

This example teaches:
- **Infrastructure as Code**: Your server setup is now version controlled
- **Reproducibility**: Identical servers every time
- **Disaster Recovery**: New server in minutes, not hours
- **Cost Control**: Destroy/recreate for testing

## Next Steps

1. **Test the deployment** in a development environment
2. **Customize** the configuration for your specific needs
3. **Add monitoring** and backup strategies
4. **Explore multi-environment** setups (dev/staging/prod)

This gives you hands-on Terraform experience while solving real problems with your existing infrastructure!