# environments.tf - Environment-specific configurations

# Local variables for environment selection
locals {
  # Environment configuration
  environments = {
    virtualbox = {
      target_host     = "192.168.56.10"
      ssh_user        = "steve"
      ssh_private_key = "~/.ssh/id_rsa"  # Your existing SSH key
      domain_suffix   = ".test.local"
      
      # VirtualBox-specific settings
      apache_listen_port = 80
      postgres_port      = 5432
      dovecot_enabled    = true
      ssl_enabled        = false  # Start with HTTP for testing
      
      # Web directories
      web_root = "/var/www"
      user_dir = "/home/steve/public_html"
      
      # Storage configuration
      has_additional_storage = true
      web_volume_device     = "/dev/sdb1"
      web_volume_mount      = "/var/www/jxqz.org"
      web_volume_size       = "5GB"  # Smaller for testing
      
      # Database settings
      db_name = "jxqz_test"
      db_user = "steve"
    }
    
    production = {
      target_host     = "jxqz.org"
      ssh_user        = "steve"
      ssh_private_key = "~/.ssh/id_rsa"
      domain_suffix   = ""
      
      # Production settings
      apache_listen_port = 80
      postgres_port      = 5432
      dovecot_enabled    = true
      ssl_enabled        = true
      
      # Web directories  
      web_root = "/var/www"
      user_dir = "/home/steve/public_html"
      
      # Storage configuration (matches actual production)
      has_additional_storage = true
      web_volume_device     = "/dev/vdb1"
      web_volume_mount      = "/var/www/jxqz.org"
      web_volume_size       = "40GB"
      
      # Database settings
      db_name = "jxqz_production"
      db_user = "steve"
    }
  }
  
  # Select environment based on terraform workspace or variable
  current_env = local.environments[var.environment]
}

# Environment selection variable
variable "environment" {
  description = "Target environment: virtualbox or production"
  type        = string
  default     = "virtualbox"
  
  validation {
    condition     = contains(["virtualbox", "production"], var.environment)
    error_message = "Environment must be either 'virtualbox' or 'production'."
  }
}

# Configuration validation
variable "config_source_path" {
  description = "Path to retrieved server configurations"
  type        = string
  default     = "../config"
}

# Output current environment info
output "environment_info" {
  value = {
    environment    = var.environment
    target_host    = local.current_env.target_host
    ssh_user       = local.current_env.ssh_user
    domains        = [
      "jxqz.org${local.current_env.domain_suffix}",
      "dx.jxqz.org${local.current_env.domain_suffix}",
      "arpoison.net${local.current_env.domain_suffix}",
      "suoc.org${local.current_env.domain_suffix}"
    ]
  }
}