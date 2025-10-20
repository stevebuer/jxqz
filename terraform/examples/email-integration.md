# Email Services with Dovecot and Cloudflare

This guide covers integrating your existing Dovecot IMAP server with the Terraform infrastructure setup.

## Current Email Setup

**Your Configuration:**
- **IMAP Server**: Dovecot
- **Hosting**: Same Vultr server as web services
- **Access**: IMAP clients connect to your server

## Email + Web Services Integration

### Firewall Configuration

The Terraform configuration includes email ports:
```hcl
# IMAP access
port 143  # Plain IMAP
port 993  # IMAP over SSL

# SMTP (if using Postfix)
port 587  # SMTP submission
```

### DNS Considerations with Cloudflare

#### Important: Email vs. Web Traffic

**Web Traffic**: Can be proxied through Cloudflare (CDN benefits)
**Email Traffic**: Must be direct to your server (no proxy)

#### DNS Record Configuration

```hcl
# Web records (can be proxied)
{
  name    = "@"              # jxqz.org
  type    = "A"
  content = "server_ip"
  proxied = true             # ✅ Web traffic through Cloudflare
}

# Email records (must NOT be proxied)
{
  name    = "@"              # MX record for email delivery
  type    = "MX"
  content = "10 jxqz.org"
  proxied = false            # ✅ Direct to server for email
}

{
  name    = "mail"           # mail.jxqz.org for IMAP clients
  type    = "A" 
  content = "server_ip"
  proxied = false            # ✅ Direct to server for IMAP
}
```

## Migration Strategy

### Phase 1: Infrastructure Setup (No Email Disruption)
```bash
# Deploy server with email ports configured
terraform apply

# Server includes:
# - Dovecot installed and ready
# - Firewall configured for email ports
# - Basic email configuration placeholder
```

### Phase 2: DNS Migration (Careful Coordination)
```bash
# Update DNS at Cloudflare
# Web traffic: Proxied through Cloudflare
# Email traffic: Direct to server

# Critical: Update MX records to point to new server IP
# Email clients: Update IMAP settings if needed
```

### Phase 3: Email Configuration Migration
```bash
# Copy your existing Dovecot configuration
rsync -av /etc/dovecot/ steve@new-server:/etc/dovecot/

# Copy user mailboxes  
rsync -av /var/mail/ steve@new-server:/var/mail/

# Copy user accounts/passwords
# (Method depends on your current auth setup)
```

## SSL for Email Services

### Current Challenge
**Without SSL**: IMAP passwords sent in plain text
**With SSL**: Encrypted IMAP connections (port 993)

### Solution: Let's Encrypt + Dovecot
```bash
# Get SSL certificate for mail subdomain
certbot certonly --apache -d mail.jxqz.org

# Configure Dovecot to use SSL certificate
# /etc/dovecot/conf.d/10-ssl.conf
ssl = required
ssl_cert = </etc/letsencrypt/live/mail.jxqz.org/fullchain.pem
ssl_key = </etc/letsencrypt/live/mail.jxqz.org/privkey.pem
```

## Email Client Configuration

### IMAP Settings (After Migration)
**Server**: mail.jxqz.org (or jxqz.org)
**Port**: 993 (SSL) or 143 (plain)
**Security**: SSL/TLS recommended
**Authentication**: Your existing method

### Why NOT mail.jxqz.org Through Cloudflare Proxy
- **Email protocols** (IMAP, SMTP) don't work through HTTP proxies
- **Direct connection** required for email services
- **Cloudflare proxy** is for HTTP/HTTPS traffic only

## DNS Record Examples

### Complete Email + Web DNS Setup
```hcl
domains = {
  "jxqz" = {
    zone_id = "your-zone-id"
    records = [
      # Web traffic (proxied for performance)
      {
        name    = "@"
        type    = "A"
        content = "server_ip_auto"
        proxied = true
      },
      {
        name    = "dx"              # Analytics app
        type    = "A"
        content = "server_ip_auto"
        proxied = false             # Direct for API
      },
      
      # Email traffic (never proxied)
      {
        name    = "@"
        type    = "MX"
        content = "10 jxqz.org"     # Email delivery to root domain
        proxied = false
      },
      {
        name    = "mail"            # Optional: mail.jxqz.org
        type    = "A"
        content = "server_ip_auto"
        proxied = false             # Direct for IMAP
      }
    ]
  }
}
```

## Testing Email After Migration

### Verify DNS
```bash
# Check MX record
dig MX jxqz.org

# Check A record for mail subdomain  
dig A mail.jxqz.org

# Verify no proxy (should show your server IP directly)
nslookup mail.jxqz.org
```

### Test IMAP Connection
```bash
# Test plain IMAP
telnet mail.jxqz.org 143

# Test SSL IMAP
openssl s_client -connect mail.jxqz.org:993
```

### Email Client Test
- **Update IMAP settings** to new server
- **Test send/receive** functionality
- **Verify SSL/TLS** connections work

## Backup Strategy for Email

### Before Migration
```bash
# Backup current email configuration
tar -czf dovecot-config-backup.tar.gz /etc/dovecot/
tar -czf mail-data-backup.tar.gz /var/mail/

# Document current email client settings
# Test email functionality thoroughly
```

### After Migration
```bash
# Include email in regular backups
# Add email config to Apache backup script
cp -r /etc/dovecot/ /opt/steve/backups/
cp -r /var/mail/ /opt/steve/backups/
```

## Career Benefits

### Email Server Management
- **Dovecot configuration** experience
- **SSL/TLS** for email services
- **DNS MX records** understanding
- **Email security** best practices

### Infrastructure Integration
- **Multi-service** server management (web + email)
- **Firewall configuration** for multiple services
- **SSL certificate** management across services
- **Service coordination** during migrations

### DevOps Skills
- **Infrastructure as Code** for complete server stack
- **Service migration** planning and execution
- **DNS management** for complex setups
- **Security configuration** across multiple protocols

This setup demonstrates **full-stack infrastructure management** - web services, databases, email, DNS, and security - all managed through code and modern automation practices.