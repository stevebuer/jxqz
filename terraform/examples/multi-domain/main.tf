# Multi-Domain Server Configuration

terraform {
  required_providers {
    vultr = {
      source  = "vultr/vultr"
      version = "~> 2.0"
    }
  }
}

provider "vultr" {
  api_key     = var.vultr_api_key
  rate_limit  = 700
  retry_limit = 3
}

# Variables
variable "vultr_api_key" {
  description = "Vultr API Key"
  type        = string
  sensitive   = true
}

variable "server_label" {
  description = "Server label"
  type        = string
  default     = "steve-multi-domain-server"
}

variable "domains" {
  description = "List of domains to configure"
  type = list(object({
    name        = string
    document_root = string
    is_primary  = bool
    is_analytics = bool
  }))
  default = [
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

# Data sources
data "vultr_os" "debian" {
  filter {
    name   = "name"
    values = ["Debian 12 x64 (bookworm)"]
  }
}

data "vultr_plan" "web_server" {
  filter {
    name   = "vcpu_count"
    values = ["1"]
  }
  filter {
    name   = "ram"
    values = ["2048"] # 2GB for multiple sites + analytics app
  }
}

data "vultr_region" "primary" {
  filter {
    name   = "id"
    values = ["ewr"] # Adjust to your preferred region
  }
}

# SSH Key
resource "vultr_ssh_key" "steve_laptop" {
  name    = "steve-laptop-key"
  ssh_key = file("~/.ssh/id_rsa.pub")
}

# Firewall configuration
resource "vultr_firewall_group" "web_server" {
  description = "Multi-Domain Web Server Firewall"
}

resource "vultr_firewall_rule" "ssh" {
  firewall_group_id = vultr_firewall_group.web_server.id
  protocol          = "tcp"
  ip_type          = "v4"
  subnet           = "0.0.0.0"
  subnet_size      = 0
  port             = "22"
  notes            = "SSH access"
}

resource "vultr_firewall_rule" "http" {
  firewall_group_id = vultr_firewall_group.web_server.id
  protocol          = "tcp"
  ip_type          = "v4"
  subnet           = "0.0.0.0"
  subnet_size      = 0
  port             = "80"
  notes            = "HTTP access"
}

resource "vultr_firewall_rule" "https" {
  firewall_group_id = vultr_firewall_group.web_server.id
  protocol          = "tcp"
  ip_type          = "v4"
  subnet           = "0.0.0.0"
  subnet_size      = 0
  port             = "443"
  notes            = "HTTPS access"
}

# Database port for analytics application
resource "vultr_firewall_rule" "mysql" {
  firewall_group_id = vultr_firewall_group.web_server.id
  protocol          = "tcp"
  ip_type          = "v4"
  subnet           = "10.0.0.0"  # Restrict to private network
  subnet_size      = 8
  port             = "3306"
  notes            = "MySQL for analytics app (private network only)"
}

# Email ports for Dovecot IMAP
resource "vultr_firewall_rule" "imap" {
  firewall_group_id = vultr_firewall_group.web_server.id
  protocol          = "tcp"
  ip_type          = "v4"
  subnet           = "0.0.0.0"
  subnet_size      = 0
  port             = "143"
  notes            = "IMAP access"
}

resource "vultr_firewall_rule" "imaps" {
  firewall_group_id = vultr_firewall_group.web_server.id
  protocol          = "tcp"
  ip_type          = "v4"
  subnet           = "0.0.0.0"
  subnet_size      = 0
  port             = "993"
  notes            = "IMAP over SSL"
}

resource "vultr_firewall_rule" "smtp_submission" {
  firewall_group_id = vultr_firewall_group.web_server.id
  protocol          = "tcp"
  ip_type          = "v4"
  subnet           = "0.0.0.0"
  subnet_size      = 0
  port             = "587"
  notes            = "SMTP submission (if using Postfix)"
}

# Main server instance
resource "vultr_instance" "web_server" {
  plan              = data.vultr_plan.web_server.id
  region            = data.vultr_region.primary.id
  os_id             = data.vultr_os.debian.id
  label             = var.server_label
  hostname          = "steve-web"
  enable_ipv6       = true
  backups           = "enabled"
  ddos_protection   = true
  activation_email  = false
  
  ssh_key_ids = [vultr_ssh_key.steve_laptop.id]
  firewall_group_id = vultr_firewall_group.web_server.id

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    domains = var.domains
  }))

  tags = ["multi-domain", "web-server", "production"]
}

# Outputs
output "server_ip" {
  value = vultr_instance.web_server.main_ip
  description = "Public IP address of the web server"
}

output "server_ipv6" {
  value = vultr_instance.web_server.v6_main_ip
  description = "IPv6 address of the web server"
}

output "connection_info" {
  value = "ssh root@${vultr_instance.web_server.main_ip}"
  description = "SSH connection command"
}

output "domain_setup" {
  value = {
    for domain in var.domains : domain.name => {
      document_root = domain.document_root
      ssl_command   = "certbot --apache -d ${domain.name} -d www.${domain.name}"
      dns_record    = "A record: ${domain.name} -> ${vultr_instance.web_server.main_ip}"
    }
  }
  description = "Domain configuration details"
}

output "next_steps" {
  value = <<-EOT
    Next Steps:
    1. Update DNS records for all domains to point to: ${vultr_instance.web_server.main_ip}
    2. Deploy content: rsync -avz local-content/ steve@${vultr_instance.web_server.main_ip}:/var/www/domain/
    3. Set up SSL certificates for each domain
    4. Configure analytics database if needed
    
    Domain Status Check:
    curl -H "Host: jxqz.org" http://${vultr_instance.web_server.main_ip}
    curl -H "Host: arpoison.net" http://${vultr_instance.web_server.main_ip}
    curl -H "Host: suoc.org" http://${vultr_instance.web_server.main_ip}
  EOT
  description = "Post-deployment instructions"
}