# DNS Management with Vultr (Simple Option)

terraform {
  required_providers {
    vultr = {
      source  = "vultr/vultr"
      version = "~> 2.0"
    }
  }
}

provider "vultr" {
  api_key = var.vultr_api_key
}

variable "vultr_api_key" {
  description = "Vultr API Key"
  type        = string
  sensitive   = true
}

variable "domains" {
  description = "Domains to manage DNS for"
  type        = list(string)
  default     = ["jxqz.org", "arpoison.net", "suoc.org"]
}

# Create the server first
module "web_server" {
  source = "../multi-domain"
  
  vultr_api_key = var.vultr_api_key
  server_label  = "steve-server-with-vultr-dns"
}

# Create DNS domains in Vultr
resource "vultr_dns_domain" "domains" {
  for_each = toset(var.domains)
  domain   = each.value
}

# Create A records for root domains
resource "vultr_dns_record" "root_a_records" {
  for_each = vultr_dns_domain.domains
  
  domain = each.value.domain
  name   = ""  # Root domain
  type   = "A"
  data   = module.web_server.server_ip
  ttl    = 300
}

# Create A records for www subdomains
resource "vultr_dns_record" "www_a_records" {
  for_each = vultr_dns_domain.domains
  
  domain = each.value.domain
  name   = "www"
  type   = "A"
  data   = module.web_server.server_ip
  ttl    = 300
}

# Create A record for dx.jxqz.org analytics subdomain
resource "vultr_dns_record" "dx_subdomain" {
  depends_on = [vultr_dns_domain.domains]
  
  domain = "jxqz.org"
  name   = "dx"
  type   = "A"
  data   = module.web_server.server_ip
  ttl    = 300
}

# Outputs
output "server_ip" {
  value = module.web_server.server_ip
  description = "Server IP address"
}

output "dns_domains_created" {
  value = [for domain in vultr_dns_domain.domains : domain.domain]
  description = "DNS domains created in Vultr"
}

output "nameservers" {
  value = {
    for domain_name, domain in vultr_dns_domain.domains : domain_name => [
      "ns1.vultr.com",
      "ns2.vultr.com"
    ]
  }
  description = "Vultr nameservers - update these at your domain registrar"
}

output "dns_records" {
  value = {
    a_records = {
      for domain_name, record in vultr_dns_record.root_a_records : domain_name => {
        name = record.name == "" ? "@" : record.name
        type = record.type
        data = record.data
      }
    }
    www_records = {
      for domain_name, record in vultr_dns_record.www_a_records : domain_name => {
        name = record.name
        type = record.type
        data = record.data
      }
    }
    analytics = {
      name = vultr_dns_record.dx_subdomain.name
      type = vultr_dns_record.dx_subdomain.type
      data = vultr_dns_record.dx_subdomain.data
    }
  }
  description = "DNS records created"
}

output "next_steps" {
  value = <<-EOT
    Vultr DNS Setup Complete!
    
    ✅ Server provisioned: ${module.web_server.server_ip}
    ✅ DNS domains created in Vultr
    ✅ A records pointing to server
    
    IMPORTANT: Update nameservers at your domain registrars:
    
    For ALL domains (jxqz.org, arpoison.net, suoc.org):
    1. Go to your domain registrar (Porkbun, etc.)
    2. Change nameservers to:
       - ns1.vultr.com
       - ns2.vultr.com
    3. Wait for DNS propagation (24-48 hours)
    
    Test after propagation:
    dig jxqz.org
    dig dx.jxqz.org
    dig arpoison.net
    dig suoc.org
    
    Then proceed with SSL setup and content deployment.
  EOT
}