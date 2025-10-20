# Basic Vultr Server for JXQZ

terraform {
  required_providers {
    vultr = {
      source  = "vultr/vultr"
      version = "~> 2.0"
    }
  }
}

# Configure the Vultr Provider
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
  default     = "jxqz-web-server"
}

variable "ssh_key_name" {
  description = "SSH key name for server access"
  type        = string
  default     = "steve-laptop"
}

# Data source for OS (Debian 12)
data "vultr_os" "debian" {
  filter {
    name   = "name"
    values = ["Debian 12 x64 (bookworm)"]
  }
}

# Data source for server plan (1GB RAM, 1 vCPU - adjust as needed)
data "vultr_plan" "web_server" {
  filter {
    name   = "vcpu_count"
    values = ["1"]
  }
  filter {
    name   = "ram"
    values = ["1024"]
  }
}

# Data source for region (adjust to your preferred region)
data "vultr_region" "primary" {
  filter {
    name   = "id"
    values = ["ewr"] # New Jersey - change to your preferred region
  }
}

# SSH Key (you'll need to upload this to Vultr first or manage it via Terraform)
resource "vultr_ssh_key" "steve_laptop" {
  name    = var.ssh_key_name
  ssh_key = file("~/.ssh/id_rsa.pub") # Path to your public key
}

# Firewall for web server
resource "vultr_firewall_group" "web_server" {
  description = "JXQZ Web Server Firewall"
}

# SSH access
resource "vultr_firewall_rule" "ssh" {
  firewall_group_id = vultr_firewall_group.web_server.id
  protocol          = "tcp"
  ip_type          = "v4"
  subnet           = "0.0.0.0"
  subnet_size      = 0
  port             = "22"
  notes            = "SSH access"
}

# HTTP access
resource "vultr_firewall_rule" "http" {
  firewall_group_id = vultr_firewall_group.web_server.id
  protocol          = "tcp"
  ip_type          = "v4"
  subnet           = "0.0.0.0"
  subnet_size      = 0
  port             = "80"
  notes            = "HTTP access"
}

# HTTPS access
resource "vultr_firewall_rule" "https" {
  firewall_group_id = vultr_firewall_group.web_server.id
  protocol          = "tcp"
  ip_type          = "v4"
  subnet           = "0.0.0.0"
  subnet_size      = 0
  port             = "443"
  notes            = "HTTPS access"
}

# Main server instance
resource "vultr_instance" "web_server" {
  plan              = data.vultr_plan.web_server.id
  region            = data.vultr_region.primary.id
  os_id             = data.vultr_os.debian.id
  label             = var.server_label
  hostname          = "jxqz"
  enable_ipv6       = true
  backups           = "enabled"
  ddos_protection   = true
  activation_email  = false
  
  ssh_key_ids = [vultr_ssh_key.steve_laptop.id]
  firewall_group_id = vultr_firewall_group.web_server.id

  # Basic server setup script
  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    domain_name = "jxqz.org"
  }))

  tags = ["jxqz", "web-server", "production"]
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

output "server_id" {
  value = vultr_instance.web_server.id
  description = "Vultr instance ID"
}

output "connection_info" {
  value = "ssh root@${vultr_instance.web_server.main_ip}"
  description = "SSH connection command"
}