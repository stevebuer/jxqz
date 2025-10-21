# Vultr API Status Check - Simplified Version
# This configuration tests basic API connectivity and shows account information

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    vultr = {
      source  = "vultr/vultr"
      version = "~> 2.0"
    }
  }
}

# Configure the Vultr Provider
provider "vultr" {
  # API key will be read from VULTR_API_KEY environment variable
  rate_limit = 700
  retry_limit = 3
}

# Data sources to retrieve current Vultr resources
data "vultr_account" "current" {
  # This will get account information
}

# Connection test output
output "api_connection_test" {
  description = "API connection status"
  value = {
    status = "✅ Connected to Vultr API"
    timestamp = timestamp()
  }
}

output "account_information" {
  description = "Current Vultr account details"
  value = {
    name = data.vultr_account.current.name
    email = data.vultr_account.current.email
    balance = data.vultr_account.current.balance
    pending_charges = data.vultr_account.current.pending_charges
    acl = data.vultr_account.current.acl
  }
}

output "configuration_summary" {
  description = "Summary of current Vultr configuration"
  value = {
    api_status = "Connected"
    account_name = data.vultr_account.current.name
    account_balance = data.vultr_account.current.balance
    test_timestamp = timestamp()
    next_steps = [
      "API connectivity confirmed",
      "Ready for infrastructure automation",
      "Consider creating terraform configurations for your resources"
    ]
  }
}