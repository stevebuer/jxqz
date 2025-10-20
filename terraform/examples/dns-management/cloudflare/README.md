# DNS Management with Cloudflare

This example shows how to manage DNS records for all your domains using Terraform and Cloudflare, automatically pointing them to your Vultr server.

## Benefits of Terraform DNS Management

### Career/Learning Benefits
- **Industry Standard**: Cloudflare is used by many major companies
- **Infrastructure as Code**: DNS changes are version controlled and reproducible
- **Automation**: DNS updates happen automatically when server IP changes
- **DevOps Skills**: Essential knowledge for modern infrastructure management

### Practical Benefits
- **No Manual Updates**: DNS records update automatically when you provision new servers
- **Version Control**: All DNS changes are tracked in git
- **Disaster Recovery**: DNS configuration is preserved and reproducible
- **Multi-Environment**: Easy to create staging.jxqz.org, test.jxqz.org, etc.

## Migration from Porkbun

### Step 1: Set Up Cloudflare (Free)
1. **Create Cloudflare account** at cloudflare.com
2. **Add your domains** to Cloudflare (jxqz.org, arpoison.net, suoc.org)
3. **Get zone IDs** from Cloudflare dashboard for each domain
4. **Create API token** with Zone:Edit permissions

### Step 2: Update Nameservers at Porkbun
1. **Keep domain registration** at Porkbun (no need to transfer)
2. **Change nameservers** to Cloudflare's nameservers (provided when you add domain)
3. **Wait for propagation** (usually 24-48 hours)

### Step 3: Configure Terraform
```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your API tokens and zone IDs
```

### Step 4: Deploy
```bash
terraform init
terraform plan
terraform apply
```

## What This Configuration Does

### Automatic Server Integration
- **Provisions Vultr server** using the multi-domain configuration
- **Creates DNS records** that automatically point to the server IP
- **Manages all domains** from a single configuration

### DNS Record Types Created
- **A Records**: Point domains to your server IP
- **CNAME Records**: Automatic www redirects
- **Subdomain Support**: Separate configuration for dx.jxqz.org

### Cloudflare Features Used
- **Proxy Settings**: Enable/disable Cloudflare proxy per record
- **TTL Management**: Fast updates during development
- **Security**: DDoS protection and security features

## Configuration Details

### Domain Structure
```
jxqz.org         → Server IP (proxied through Cloudflare)
www.jxqz.org     → CNAME to jxqz.org (proxied)
dx.jxqz.org      → Server IP (direct, no proxy for API)

arpoison.net     → Server IP (proxied)
www.arpoison.net → CNAME to arpoison.net (proxied)

suoc.org         → Server IP (proxied)
www.suoc.org     → CNAME to suoc.org (proxied)
```

### Proxy Settings
- **Main domains**: Proxied through Cloudflare (performance + security)
- **Analytics subdomain**: Direct connection (APIs work better without proxy)
- **TTL**: 300 seconds for fast updates during setup

## Usage Examples

### Basic Deployment
```bash
# Deploy everything (server + DNS)
terraform apply

# Check DNS propagation
dig jxqz.org
dig dx.jxqz.org
nslookup arpoison.net
```

### Adding New Subdomains
```hcl
# In terraform.tfvars, add to existing domain:
records = [
  # ... existing records ...
  {
    name    = "staging"        # staging.jxqz.org
    type    = "A"
    content = "server_ip_auto"
    ttl     = 300
    proxied = false
  }
]
```

### Environment-Specific DNS
```bash
# Create staging environment with different DNS
terraform workspace new staging
terraform apply -var="server_label=jxqz-staging"
```

## Cost Analysis

### Cloudflare Free Tier Includes:
- **Unlimited DNS queries**
- **DDoS protection**
- **SSL certificates**
- **Basic analytics**
- **Page rules** (3 free)

### Comparison with Manual Management:
| Method | Cost | Time | Reliability | Learning Value |
|--------|------|------|-------------|----------------|
| Manual (Porkbun) | $0 | High | Human error prone | Low |
| Terraform + Cloudflare | $0 | Low | Reproducible | High |

## Advanced Features

### Multi-Environment Support
```bash
# Production
terraform workspace select default
terraform apply

# Staging
terraform workspace new staging
terraform apply -var="server_label=staging-server"
```

### Integration with CI/CD
```yaml
# GitHub Actions example
- name: Update DNS
  run: |
    terraform init
    terraform apply -auto-approve
```

### Monitoring and Alerts
- **Cloudflare Analytics**: Built-in traffic and performance monitoring
- **Health Checks**: Can be added to monitor server availability
- **Email Alerts**: Notify when DNS changes are made

## Troubleshooting

### Check DNS Propagation
```bash
# Test from multiple locations
dig @8.8.8.8 jxqz.org        # Google DNS
dig @1.1.1.1 jxqz.org        # Cloudflare DNS
dig @208.67.222.222 jxqz.org # OpenDNS

# Check specific record types
dig A jxqz.org
dig CNAME www.jxqz.org
```

### Verify Terraform State
```bash
terraform show
terraform state list
terraform refresh
```

## Career Benefits

This configuration demonstrates several valuable skills:

### Infrastructure as Code
- **DNS management** through code instead of manual processes
- **Version control** for infrastructure changes
- **Reproducible environments**

### Cloud Services
- **Cloudflare** experience (major CDN/security provider)
- **Multi-provider** infrastructure (Vultr + Cloudflare)
- **API integration** and automation

### DevOps Practices
- **Automation** of manual processes
- **Environment management** (dev/staging/prod)
- **Infrastructure monitoring** and maintenance

This setup gives you production-ready DNS management while building skills that are highly valued in the job market!