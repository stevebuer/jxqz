# DNS Migration Guide: From Manual to Infrastructure as Code

This guide helps you transition from manual DNS management at Porkbun to automated Infrastructure as Code DNS management.

## Current State vs Target State

### Current (Manual)
- **Domain Registration**: Porkbun.com
- **DNS Management**: Porkbun web interface
- **Server Management**: Manual Vultr setup
- **Updates**: Manual changes when needed

### Target (Infrastructure as Code)
- **Domain Registration**: Keep at Porkbun
- **DNS Management**: Terraform automation
- **Server Management**: Terraform automation
- **Updates**: Git commits → automatic deployment

## Migration Options

### Option 1: Cloudflare DNS (Recommended for Career)

**Best for:** Learning industry-standard tools, career advancement

**Benefits:**
- Industry-standard experience (Cloudflare is everywhere)
- Advanced features (CDN, DDoS protection, analytics)
- Free tier with excellent features
- Better job market relevance

**Process:**
1. Create free Cloudflare account
2. Add domains to Cloudflare
3. Update nameservers at Porkbun
4. Deploy with Terraform

**Example Cost:** $0/month (free tier) + current server costs

### Option 2: Vultr DNS (Recommended for Simplicity)

**Best for:** Learning fundamentals, single-provider simplicity

**Benefits:**
- Everything in one place (server + DNS)
- Simpler setup process
- One API key to manage
- Good foundation for learning

**Process:**
1. Deploy Terraform configuration
2. Update nameservers at Porkbun
3. Wait for propagation

**Example Cost:** $0 additional (included with server)

## Step-by-Step Migration (Cloudflare)

### Phase 1: Preparation (No Downtime)
```bash
# 1. Create Cloudflare account at cloudflare.com
# 2. Add domains to Cloudflare (don't change nameservers yet)
# 3. Get API token and zone IDs
# 4. Configure Terraform

cd terraform/examples/dns-management/cloudflare/
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your credentials and zone IDs
```

### Phase 2: Test Configuration (No Downtime)
```bash
# Test what Terraform would do
terraform init
terraform plan

# This shows you exactly what DNS records will be created
# Verify they match your current setup
```

### Phase 3: Deploy Infrastructure (No Downtime)
```bash
# Deploy server and DNS records
terraform apply

# Note the server IP that was created
# DNS records are created but not active yet (nameservers still at Porkbun)
```

### Phase 4: Switch DNS (Brief Propagation Period)
```bash
# At Porkbun, update nameservers for ALL domains to:
# - ns1.cloudflare.com (varies by account)
# - ns2.cloudflare.com (varies by account)
# (Cloudflare will show you the exact nameservers to use)

# Wait 24-48 hours for full propagation
```

### Phase 5: Verify and Clean Up
```bash
# Test all domains
dig jxqz.org
dig dx.jxqz.org
dig arpoison.net
dig suoc.org

# Deploy your content
rsync -avz ~/sites/ steve@<server-ip>:/var/www/

# Set up SSL
ssh steve@<server-ip>
sudo certbot --apache -d jxqz.org -d www.jxqz.org
sudo certbot --apache -d dx.jxqz.org
# ... etc for other domains
```

## Step-by-Step Migration (Vultr DNS)

### Simpler Process
```bash
cd terraform/examples/dns-management/vultr/
cp terraform.tfvars.example terraform.tfvars
# Edit with your Vultr API key

# Deploy everything
terraform apply

# Update nameservers at Porkbun to:
# - ns1.vultr.com
# - ns2.vultr.com

# Wait for propagation, then test and deploy content
```

## Risk Mitigation

### Backup Current DNS
Before starting, document your current DNS setup:
```bash
# Document current DNS records
dig jxqz.org ANY
dig arpoison.net ANY
dig suoc.org ANY

# Save the output for reference
```

### Gradual Migration
1. **Test with one domain first** (maybe suoc.org since it's small)
2. **Verify everything works** before migrating other domains
3. **Keep Porkbun access** until fully migrated

### Rollback Plan
If something goes wrong:
1. **Change nameservers back** to Porkbun at the registrar
2. **DNS will revert** to Porkbun management
3. **No permanent damage** - domain registration stays at Porkbun

## Timeline and Expectations

### Realistic Timeline
- **Preparation**: 1-2 hours (learning, setup)
- **Testing**: 30 minutes (terraform plan)
- **Deployment**: 15 minutes (terraform apply)
- **DNS Propagation**: 24-48 hours (waiting)
- **Verification**: 1 hour (testing, SSL setup)

### What to Expect
- **Brief learning curve** with Terraform concepts
- **DNS propagation delay** is normal and expected
- **Some domains may resolve before others** during propagation
- **SSL certificates** may need to be regenerated after migration

## Benefits After Migration

### Immediate Benefits
- **No more manual DNS changes**
- **Version-controlled infrastructure**
- **Automated server + DNS deployment**
- **Disaster recovery in minutes**

### Career Benefits
- **Infrastructure as Code** experience
- **Terraform** skills (highly marketable)
- **Cloud services** experience (Cloudflare/Vultr)
- **DevOps practices** demonstration

### Portfolio Value
- **Real infrastructure project** solving actual problems
- **Before/after comparison** showing modernization
- **Documentation** of migration process
- **GitHub repository** demonstrating skills

## Recommendation

**For your situation:** Start with **Cloudflare DNS** because:

1. **Career Value**: Cloudflare experience is highly valued
2. **Free Tier**: No additional cost
3. **Learning**: More comprehensive DNS feature set
4. **Portfolio**: Better story for job interviews
5. **Future**: Easier to scale and add features

The migration gives you real Infrastructure as Code experience while solving actual problems in your current setup - exactly the kind of project that demonstrates valuable skills to potential employers.

## Support During Migration

If you encounter issues:
1. **DNS propagation checkers**: Use online tools to verify propagation
2. **Terraform state**: `terraform show` and `terraform state list` help debug
3. **Rollback**: Simply change nameservers back to Porkbun if needed
4. **Testing**: Use `dig @8.8.8.8 domain.com` to test from different DNS servers

This migration transforms your manual infrastructure into modern, version-controlled, automated infrastructure while building valuable career skills.