# virtualbox.tf - VirtualBox-specific Terraform configuration

# SSH connection to VirtualBox VM
resource "null_resource" "virtualbox_connection_test" {
  count = var.environment == "virtualbox" ? 1 : 0
  
  # Test connection to VM
  provisioner "remote-exec" {
    inline = [
      "echo 'Connected to VirtualBox VM successfully'",
      "hostname",
      "whoami",
      "date"
    ]
    
    connection {
      type        = "ssh"
      host        = local.current_env.target_host
      user        = local.current_env.ssh_user
      private_key = file(local.current_env.ssh_private_key)
    }
  }
  
  triggers = {
    always_run = timestamp()
  }
}

# Test storage configuration
resource "null_resource" "virtualbox_storage_setup" {
  count = var.environment == "virtualbox" && local.current_env.has_additional_storage ? 1 : 0
  
  depends_on = [null_resource.virtualbox_connection_test]
  
  # Verify and setup storage
  provisioner "remote-exec" {
    inline = [
      "echo 'Checking storage configuration...'",
      
      # Check if additional storage is available
      "if [ -b ${local.current_env.web_volume_device} ]; then",
      "  echo 'Additional storage volume found: ${local.current_env.web_volume_device}'",
      "  df -h ${local.current_env.web_volume_mount} || echo 'Volume not yet mounted'",
      "else",
      "  echo 'Warning: Additional storage volume ${local.current_env.web_volume_device} not found'",
      "  echo 'Continuing with primary disk setup...'",
      "fi",
      
      # Ensure mount point exists and has proper permissions
      "sudo mkdir -p ${local.current_env.web_volume_mount}",
      "sudo chown steve:www-data ${local.current_env.web_volume_mount}",
      "sudo chmod 755 ${local.current_env.web_volume_mount}",
      
      # Verify mount and show storage info
      "echo 'Storage status:'",
      "df -h | grep -E '(Filesystem|${local.current_env.web_volume_mount}|/dev/sd)'",
      "echo 'Mount info:'", 
      "mount | grep '${local.current_env.web_volume_mount}' || echo 'No specific mount found'",
      
      "echo 'Storage configuration verified'"
    ]
    
    connection {
      type        = "ssh"
      host        = local.current_env.target_host
      user        = local.current_env.ssh_user
      private_key = file(local.current_env.ssh_private_key)
    }
  }
}

# Deploy Apache configuration to VirtualBox
resource "null_resource" "virtualbox_apache_config" {
  count = var.environment == "virtualbox" ? 1 : 0
  
  depends_on = [null_resource.virtualbox_storage_setup]
  
  # Copy Apache configurations
  provisioner "file" {
    source      = "${var.config_source_path}/selective-configs-20251020-152136/scripts/github-configs/cs330-projects/homework2/config/"
    destination = "/tmp/apache-configs"
    
    connection {
      type        = "ssh"
      host        = local.current_env.target_host
      user        = local.current_env.ssh_user
      private_key = file(local.current_env.ssh_private_key)
    }
  }
  
  # Apply Apache configuration
  provisioner "remote-exec" {
    inline = [
      "echo 'Configuring Apache for VirtualBox testing...'",
      
      # Create test virtual hosts
      "sudo tee /etc/apache2/sites-available/jxqz.test.conf << 'EOF'",
      "<VirtualHost *:80>",
      "    ServerName jxqz.test.local",
      "    DocumentRoot /var/www/jxqz.org",
      "    ErrorLog \\${APACHE_LOG_DIR}/jxqz.test-error.log", 
      "    CustomLog \\${APACHE_LOG_DIR}/jxqz.test-access.log combined",
      "</VirtualHost>",
      "EOF",
      
      "sudo tee /etc/apache2/sites-available/dx.test.conf << 'EOF'",
      "<VirtualHost *:80>",
      "    ServerName dx.test.local",
      "    DocumentRoot /var/www/dx.jxqz.org/public_html",
      "    ErrorLog \\${APACHE_LOG_DIR}/dx.test-error.log",
      "    CustomLog \\${APACHE_LOG_DIR}/dx.test-access.log combined",
      "</VirtualHost>",
      "EOF",
      
      # Enable test sites
      "sudo a2ensite jxqz.test.conf",
      "sudo a2ensite dx.test.conf",
      
      # Test configuration and reload
      "sudo apache2ctl configtest",
      "sudo systemctl reload apache2",
      
      # Create basic test content
      "sudo mkdir -p /var/www/jxqz.org /var/www/dx.jxqz.org/public_html",
      "echo '<h1>JXQZ Test Site</h1><p>VirtualBox deployment successful!</p><p>Storage: ${local.current_env.web_volume_size}</p>' | sudo tee /var/www/jxqz.org/index.html",
      "echo '<h1>DX Test Site</h1><p>Analytics app testing</p>' | sudo tee /var/www/dx.jxqz.org/public_html/index.html",
      
      # Set proper ownership for web content
      "sudo chown -R steve:www-data /var/www/jxqz.org",
      "sudo chown -R steve:www-data /var/www/dx.jxqz.org",
      
      "echo 'Apache configuration complete!'"
    ]
    
    connection {
      type        = "ssh"
      host        = local.current_env.target_host
      user        = local.current_env.ssh_user
      private_key = file(local.current_env.ssh_private_key)
    }
  }
}

# Deploy Dovecot configuration to VirtualBox
resource "null_resource" "virtualbox_dovecot_config" {
  count = var.environment == "virtualbox" && local.current_env.dovecot_enabled ? 1 : 0
  
  depends_on = [null_resource.virtualbox_apache_config]
  
  # Copy Dovecot configurations  
  provisioner "file" {
    source      = "${var.config_source_path}/dovecot-config-20251020-152559/"
    destination = "/tmp/dovecot-configs"
    
    connection {
      type        = "ssh"
      host        = local.current_env.target_host
      user        = local.current_env.ssh_user
      private_key = file(local.current_env.ssh_private_key)
    }
  }
  
  # Apply Dovecot configuration
  provisioner "remote-exec" {
    inline = [
      "echo 'Configuring Dovecot for testing...'",
      
      # Backup original configs
      "sudo cp -r /etc/dovecot /etc/dovecot.backup.$(date +%Y%m%d)",
      
      # Apply basic Dovecot config for testing
      "sudo cp -r /tmp/dovecot-configs/* /etc/dovecot/",
      "sudo chown -R root:root /etc/dovecot",
      
      # Remove private keys for testing (use test certs)
      "sudo rm -f /etc/dovecot/private/dovecot.key /etc/dovecot/private/dovecot.pem",
      
      # Test configuration and restart
      "sudo dovecot -n > /tmp/dovecot-test.conf",
      "sudo systemctl restart dovecot",
      "sudo systemctl status dovecot --no-pager",
      
      "echo 'Dovecot configuration complete!'"
    ]
    
    connection {
      type        = "ssh"
      host        = local.current_env.target_host
      user        = local.current_env.ssh_user
      private_key = file(local.current_env.ssh_private_key)
    }
  }
}

# Test gallery script deployment
resource "null_resource" "virtualbox_gallery_scripts" {
  count = var.environment == "virtualbox" ? 1 : 0
  
  depends_on = [null_resource.virtualbox_apache_config]
  
  # Copy gallery scripts
  provisioner "file" {
    source      = "../jxqz.sh"
    destination = "/tmp/jxqz.sh"
    
    connection {
      type        = "ssh"
      host        = local.current_env.target_host
      user        = local.current_env.ssh_user
      private_key = file(local.current_env.ssh_private_key)
    }
  }
  
  provisioner "file" {
    source      = "../jxqz-auto.sh"
    destination = "/tmp/jxqz-auto.sh"
    
    connection {
      type        = "ssh"
      host        = local.current_env.target_host
      user        = local.current_env.ssh_user
      private_key = file(local.current_env.ssh_private_key)
    }
  }
  
  # Test gallery script functionality
  provisioner "remote-exec" {
    inline = [
      "echo 'Testing gallery scripts...'",
      
      # Install scripts
      "chmod +x /tmp/jxqz*.sh",
      "sudo cp /tmp/jxqz*.sh /usr/local/bin/",
      
      # Create test gallery
      "mkdir -p /home/steve/test-gallery",
      "cd /home/steve/test-gallery",
      
      # Test help functionality
      "jxqz-auto.sh help",
      
      "echo 'Gallery scripts installed successfully!'"
    ]
    
    connection {
      type        = "ssh"
      host        = local.current_env.target_host
      user        = local.current_env.ssh_user
      private_key = file(local.current_env.ssh_private_key)
    }
  }
}

# VirtualBox deployment outputs
output "virtualbox_info" {
  value = var.environment == "virtualbox" ? {
    vm_ip           = local.current_env.target_host
    web_access      = "http://localhost:8080"
    ssh_command     = "ssh ${local.current_env.ssh_user}@${local.current_env.target_host}"
    test_sites      = [
      "http://localhost:8080 (default)",
      "http://jxqz.test.local:8080 (add to /etc/hosts)",
      "http://dx.test.local:8080 (add to /etc/hosts)"
    ]
    services_status = "Run: ssh ${local.current_env.ssh_user}@${local.current_env.target_host} 'sudo systemctl status apache2 dovecot postgresql'"
  } : null
}