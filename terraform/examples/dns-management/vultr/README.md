# DNS Management with Vultr (Simple Option)

This example shows DNS management using Vultr's DNS service - simpler than Cloudflare but still provides Infrastructure as Code benefits.

## Why Choose Vultr DNS?

### Advantages
- **Single Provider**: Everything in one place (server + DNS)
- **Simpler Setup**: Only one API key needed
- **Free**: No additional cost beyond server hosting
- **Good for Learning**: Fewer moving parts to understand

### Limitations
- **No CDN**: No built-in content delivery network
- **Basic Features**: Fewer advanced DNS features
- **No Proxy**: No DDoS protection at DNS level

## Migration from Porkbun

### What Changes
- **Nameservers**: Update at Porkbun to point to Vultr
- **DNS Management**: Move from Porkbun interface to Terraform
- **Domain Registration**: Keep at Porkbun (no transfer needed)

### Step-by-Step Migration

#### Step 1: Deploy with Terraform
```bash
cp terraform.tfvars.example terraform.tfvars
# Edit with your Vultr API key
terraform init
terraform apply
```

#### Step 2: Update Nameservers at Porkbun
For each domain (jxqz.org, arpoison.net, suoc.org):
1. Log into Porkbun account
2. Go to domain management
3. Change nameservers to:
   - `ns1.vultr.com`
   - `ns2.vultr.com`
4. Save changes

#### Step 3: Wait for Propagation
- **Time**: 24-48 hours typical
- **Check**: Use `dig domain.com` to verify

#### Step 4: Test and Deploy
```bash
# Test DNS
dig jxqz.org
dig dx.jxqz.org

# Deploy content
ssh steve@<server-ip>
# ... deploy your sites ...
```

## What This Configuration Creates

### DNS Records
```
jxqz.org         A    <server-ip>
www.jxqz.org     A    <server-ip>
dx.jxqz.org      A    <server-ip>

arpoison.net     A    <server-ip>
www.arpoison.net A    <server-ip>

suoc.org         A    <server-ip>
www.suoc.org     A    <server-ip>
```

### Infrastructure
- **Vultr Server**: Multi-domain configuration
- **DNS Domains**: Created in Vultr DNS
- **A Records**: All pointing to server IP
- **TTL**: 300 seconds for fast updates

## Comparison: Vultr vs Cloudflare DNS

| Feature | Vultr DNS | Cloudflare DNS |
|---------|-----------|----------------|
| **Cost** | Free with server | Free |
| **Setup Complexity** | Simple | Moderate |
| **CDN/Proxy** | No | Yes |
| **DDoS Protection** | Server-level only | DNS + Proxy level |
| **Analytics** | Basic | Advanced |
| **API Quality** | Good | Excellent |
| **Learning Value** | Good for basics | Better for career |

## When to Choose Vultr DNS

### Good Choice If:
- **Learning Infrastructure as Code** fundamentals
- **Want simplicity** over advanced features
- **Single provider** preference
- **Cost-conscious** (everything in one bill)

### Consider Cloudflare If:
- **Career advancement** is priority
- **Performance matters** (CDN benefits)
- **Security is important** (DDoS protection)
- **Advanced features** needed

## Usage Examples

### Basic Deployment
```bash
terraform apply
# Wait for nameserver updates at registrar
# Test: dig jxqz.org
```

### Adding New Subdomains
```hcl
# Add to main.tf:
resource "vultr_dns_record" "staging" {
  domain = "jxqz.org"
  name   = "staging"
  type   = "A"
  data   = module.web_server.server_ip
  ttl    = 300
}
```

### Multiple Environments
```bash
# Production
terraform workspace select default
terraform apply

# Staging with different server
terraform workspace new staging
terraform apply -var="server_label=staging-server"
```

## Monitoring and Management

### Check DNS Status
```bash
# Test resolution
dig @ns1.vultr.com jxqz.org
dig @ns2.vultr.com jxqz.org

# Check from external DNS
dig @8.8.8.8 jxqz.org
```

### Terraform Management
```bash
# See current state
terraform show

# Update DNS records
terraform apply

# Remove everything
terraform destroy
```

## Migration Path

### Start Here → Evolve Later
1. **Phase 1**: Learn with Vultr DNS (simpler)
2. **Phase 2**: Add Cloudflare for performance
3. **Phase 3**: Migrate to Cloudflare for career skills

### Easy Migration to Cloudflare
The Terraform skills you learn here transfer directly:
- Same concepts (resources, variables, outputs)
- Similar DNS record management
- Just different provider syntax

## Cost Analysis

### Vultr DNS Total Cost
- **Server**: ~$15/month (multi-domain setup)
- **DNS**: $0 (included)
- **Total**: ~$15/month

### Benefits vs Manual
- **Time Savings**: No manual DNS updates
- **Reliability**: No human errors
- **Version Control**: All changes tracked
- **Disaster Recovery**: Reproducible setup

This approach gives you Infrastructure as Code experience while keeping complexity manageable for learning!