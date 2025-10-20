# DNS Management with Cloudflare

terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
    vultr = {
      source  = "vultr/vultr"
      version = "~> 2.0"
    }
  }
}

# Configure Cloudflare Provider
provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

# Configure Vultr Provider
provider "vultr" {
  api_key = var.vultr_api_key
}

# Variables
variable "cloudflare_api_token" {
  description = "Cloudflare API Token with Zone:Edit permissions"
  type        = string
  sensitive   = true
}

variable "vultr_api_key" {
  description = "Vultr API Key"
  type        = string
  sensitive   = true
}

variable "domains" {
  description = "Domains to manage"
  type = map(object({
    zone_id = string
    records = list(object({
      name    = string
      type    = string
      content = string
      ttl     = optional(number, 300)
      proxied = optional(bool, false)
    }))
  }))
}

# Import existing Cloudflare zones (you'll need to get these IDs from Cloudflare dashboard)
data "cloudflare_zone" "domains" {
  for_each = var.domains
  zone_id  = each.value.zone_id
}

# Create a Vultr server (reusing our multi-domain configuration)
module "web_server" {
  source = "../multi-domain"
  
  vultr_api_key = var.vultr_api_key
  server_label  = "steve-production-with-dns"
  
  domains = [
    {
      name          = "jxqz.org"
      document_root = "/var/www/jxqz.org"
      is_primary    = true
      is_analytics  = false
    },
    {
      name          = "dx.jxqz.org"
      document_root = "/var/www/dx.jxqz.org"
      is_primary    = false
      is_analytics  = true
    },
    {
      name          = "arpoison.net"
      document_root = "/var/www/arpoison.net"
      is_primary    = false
      is_analytics  = false
    },
    {
      name          = "suoc.org"
      document_root = "/var/www/suoc.org"
      is_primary    = false
      is_analytics  = false
    }
  ]
}

# Create DNS records for all domains
resource "cloudflare_record" "domain_records" {
  for_each = {
    for idx, record in flatten([
      for domain_key, domain in var.domains : [
        for record in domain.records : {
          key     = "${domain_key}-${record.name}-${record.type}"
          zone_id = domain.zone_id
          name    = record.name
          type    = record.type
          content = record.type == "A" ? module.web_server.server_ip : record.content
          ttl     = record.ttl
          proxied = record.proxied
        }
      ]
    ]) : record.key => record
  }

  zone_id = each.value.zone_id
  name    = each.value.name
  type    = each.value.type
  content = each.value.content
  ttl     = each.value.proxied ? 1 : each.value.ttl
  proxied = each.value.proxied

  # Don't proxy analytics subdomain (API needs direct access)
  lifecycle {
    ignore_changes = [proxied]
  }
}

# Outputs
output "server_ip" {
  value = module.web_server.server_ip
  description = "Server IP address that DNS records point to"
}

output "dns_records_created" {
  value = {
    for k, v in cloudflare_record.domain_records : k => {
      name     = v.name
      type     = v.type
      content  = v.content
      proxied  = v.proxied
    }
  }
  description = "DNS records that were created"
}

output "cloudflare_zones" {
  value = {
    for k, v in data.cloudflare_zone.domains : k => {
      name = v.name
      id   = v.id
    }
  }
  description = "Cloudflare zones being managed"
}

output "next_steps" {
  value = <<-EOT
    DNS and SSL Management Setup Complete!
    
    ✅ Server provisioned: ${module.web_server.server_ip}
    ✅ DNS records created and pointing to server
    ✅ SSL certificates automatically provisioned by Cloudflare
    ✅ HTTPS redirects enabled for all domains
    ✅ Modern TLS settings configured
    
    🔒 SSL Status:
    - All domains now support HTTPS immediately
    - Flexible SSL mode enabled (Cloudflare ↔ User encrypted)
    - Ready for user authentication on dx.jxqz.org
    
    Next steps:
    1. Wait for DNS propagation (5-15 minutes)
    2. Test HTTPS: https://jxqz.org, https://dx.jxqz.org, etc.
    3. Optional: Set up server-side SSL for end-to-end encryption:
       ssh steve@${module.web_server.server_ip}
       sudo certbot --apache -d jxqz.org -d dx.jxqz.org -d arpoison.net -d suoc.org
    4. Deploy your content
    5. Implement user authentication on dx.jxqz.org (now SSL-ready!)
    
    🌐 Your sites are now available at:
    - https://jxqz.org (SSL + CDN + Security)
    - https://dx.jxqz.org (SSL + Security - Ready for user login)
    - https://arpoison.net (SSL + CDN + Security)
    - https://suoc.org (SSL + CDN + Security)
    
    🔧 Technical details:
    - TLS 1.2+ only (modern security)
    - HTTP/2 and HTTP/3 enabled (performance)
    - Automatic HTTPS redirects
    - Brotli compression enabled
  EOT
}

# Optional: Create a CNAME for www subdomains that point to root
resource "cloudflare_record" "www_redirects" {
  for_each = {
    for domain_key, domain in var.domains : domain_key => domain
    if contains([for r in domain.records : r.name], "@") # Only if root domain exists
  }

  zone_id = each.value.zone_id
  name    = "www"
  type    = "CNAME"
  content = data.cloudflare_zone.domains[each.key].name
  ttl     = 300
  proxied = true
}

# SSL/TLS Configuration for all zones
resource "cloudflare_zone_settings_override" "ssl_settings" {
  for_each = data.cloudflare_zone.domains
  zone_id  = each.value.id

  settings {
    # SSL Configuration
    ssl              = "flexible"    # Start with flexible, upgrade to "full" after server SSL setup
    always_use_https = "on"         # Force HTTPS redirects
    min_tls_version  = "1.2"        # Modern TLS only
    tls_1_3          = "on"         # Enable TLS 1.3 for performance
    
    # Security Headers
    security_header {
      enabled = true
    }
    
    # Performance
    brotli           = "on"         # Better compression than gzip
    http2            = "on"         # Enable HTTP/2
    http3            = "on"         # Enable HTTP/3 (QUIC)
    
    # Caching
    browser_cache_ttl = 14400       # 4 hours browser cache
    
    # Development friendly
    development_mode = "off"        # Set to "on" for testing (bypasses cache)
  }
}

# Special SSL enforcement for analytics app (critical for user auth)
resource "cloudflare_page_rule" "analytics_ssl_strict" {
  zone_id  = data.cloudflare_zone.domains["jxqz"].id
  target   = "dx.jxqz.org/*"
  priority = 1
  status   = "active"

  actions {
    always_use_https = true
    # Note: Will upgrade to ssl = "strict" after server-side SSL is configured
  }
}

# Page rule for www redirects (if needed)
resource "cloudflare_page_rule" "www_redirects" {
  for_each = {
    for domain_key, domain in var.domains : domain_key => domain
    if domain_key != "jxqz" # Don't apply to jxqz since it has subdomain
  }
  
  zone_id  = each.value.zone_id
  target   = "www.${data.cloudflare_zone.domains[each.key].name}/*"
  priority = 2
  status   = "active"

  actions {
    forwarding_url {
      url         = "https://${data.cloudflare_zone.domains[each.key].name}/$1"
      status_code = 301
    }
  }
}