# Storage configuration variables for production recreation

variable "enable_additional_storage" {
  description = "Create additional storage volume for web content"
  type        = bool
  default     = true
}

variable "web_volume_size" {
  description = "Size of web content volume in GB"
  type        = number
  default     = 40
}

variable "web_volume_mount" {
  description = "Mount point for web content volume"
  type        = string
  default     = "/var/www/jxqz.org"
}

variable "web_volume_filesystem" {
  description = "Filesystem type for web volume"
  type        = string
  default     = "ext4"
}

variable "web_volume_options" {
  description = "Mount options for web volume"
  type        = string
  default     = "defaults,noatime,nofail"
}

# Local configuration for storage
locals {
  storage_config = {
    production = {
      primary_disk_size    = 10  # GB
      web_volume_size     = var.web_volume_size
      web_mount_point     = var.web_volume_mount
      web_filesystem      = var.web_volume_filesystem
      web_mount_options   = var.web_volume_options
    }
    
    virtualbox = {
      # For testing, simulate with host directory or second disk
      primary_disk_size    = 10  # GB  
      web_volume_size     = 5    # Smaller for testing
      web_mount_point     = var.web_volume_mount
      web_filesystem      = var.web_volume_filesystem
      web_mount_options   = "defaults,noatime"  # Remove nofail for testing
    }
  }
}
