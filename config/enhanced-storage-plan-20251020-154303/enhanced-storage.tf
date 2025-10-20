# Enhanced storage configuration with consolidated web content

# Storage configuration variables
variable "enhanced_storage_layout" {
  description = "Use enhanced storage layout with consolidated web content"
  type        = bool
  default     = false  # Set to true when ready to migrate
}

variable "web_content_mount" {
  description = "Mount point for consolidated web content"
  type        = string
  default     = "/web-content"
}

# Enhanced storage paths
locals {
  storage_layout = var.enhanced_storage_layout ? {
    # Enhanced layout - all web content on dedicated volume
    web_volume_mount = var.web_content_mount
    jxqz_document_root = "${var.web_content_mount}/sites/jxqz.org"
    dx_document_root = "${var.web_content_mount}/sites/dx.jxqz.org/public_html"
    arpoison_document_root = "${var.web_content_mount}/sites/arpoison.net"
    suoc_document_root = "${var.web_content_mount}/sites/suoc.org"
    user_dir_path = "${var.web_content_mount}/user/*/public_html"
    steve_public_html = "${var.web_content_mount}/user/steve/public_html"
    
    # Compatibility symlinks
    create_symlinks = true
    symlink_targets = {
      "/var/www/jxqz.org" = "${var.web_content_mount}/sites/jxqz.org"
      "/var/www/dx.jxqz.org" = "${var.web_content_mount}/sites/dx.jxqz.org"
      "/var/www/arpoison.net" = "${var.web_content_mount}/sites/arpoison.net"
      "/var/www/suoc.org" = "${var.web_content_mount}/sites/suoc.org"
      "/home/steve/public_html" = "${var.web_content_mount}/user/steve/public_html"
    }
  } : {
    # Current layout - keep existing configuration
    web_volume_mount = "/var/www/jxqz.org"
    jxqz_document_root = "/var/www/jxqz.org"
    dx_document_root = "/var/www/dx.jxqz.org/public_html"
    arpoison_document_root = "/var/www/arpoison.net"
    suoc_document_root = "/var/www/suoc.org"
    user_dir_path = "/home/*/public_html"
    steve_public_html = "/home/steve/public_html"
    
    create_symlinks = false
    symlink_targets = {}
  }
}

# Output storage configuration for reference
output "storage_configuration" {
  value = {
    layout_type = var.enhanced_storage_layout ? "enhanced" : "current"
    mount_point = local.storage_layout.web_volume_mount
    document_roots = {
      jxqz = local.storage_layout.jxqz_document_root
      dx = local.storage_layout.dx_document_root
      arpoison = local.storage_layout.arpoison_document_root
      suoc = local.storage_layout.suoc_document_root
    }
    user_directory = local.storage_layout.user_dir_path
    symlinks_enabled = local.storage_layout.create_symlinks
  }
}
