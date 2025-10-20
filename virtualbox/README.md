# VirtualBox Testing Environment

This directory contains a complete VirtualBox testing environment for the JXQZ project. It allows you to test Infrastructure as Code deployments, configuration changes, and application deployments in a clean, isolated environment that mirrors your production Vultr server.

## Quick Start

```bash
# 1. Start the VM
./vm-test.sh start

# 2. Deploy your configurations
./vm-test.sh deploy

# 3. Test the deployment
./vm-test.sh test

# 4. Access the web interface
./vm-test.sh web

# 5. SSH into the VM for debugging
./vm-test.sh ssh

# 6. Clean up when done
./vm-test.sh destroy
```

## What Gets Created

### Virtual Machine Specifications
- **OS:** Debian 12 (Bookworm) - matches your production server
- **Memory:** 2GB RAM
- **CPU:** 2 cores
- **IP:** 192.168.56.10 (host-only network)
- **Hostname:** jxqz-test

### Installed Software
- **Apache2** with modules: rewrite, userdir, ssl, wsgi, headers
- **PostgreSQL** with test database
- **Dovecot** IMAP/POP3 email server
- **ImageMagick** for gallery script testing
- **Python3** with Flask dependencies
- **Development tools:** git, vim, curl, etc.

### Port Forwarding
| Service | VM Port | Host Port | Access |
|---------|---------|-----------|--------|
| HTTP | 80 | 8080 | http://localhost:8080 |
| HTTPS | 443 | 8443 | https://localhost:8443 |
| IMAP | 143 | 1143 | Mail client testing |
| IMAPS | 993 | 9993 | Secure mail testing |
| PostgreSQL | 5432 | 15432 | Database access |

## File Structure

```
virtualbox/
├── Vagrantfile              # VM configuration
├── provision-terraform.sh   # Advanced provisioning
├── vm-test.sh              # Management script
└── README.md               # This file
```

## Testing Workflow

### 1. Environment Setup
```bash
# Prerequisites: VirtualBox, Vagrant, Terraform installed
./vm-test.sh start          # Creates VM, installs packages
```

### 2. Configuration Deployment
```bash
./vm-test.sh deploy         # Uses Terraform to deploy configs
```

This deploys:
- Apache virtual hosts for testing
- Dovecot email server configuration
- Gallery generation scripts
- Your retrieved server configurations

### 3. Testing and Validation
```bash
./vm-test.sh test           # Automated testing
./vm-test.sh status         # Check service status
./vm-test.sh logs           # View service logs
```

### 4. Manual Testing
```bash
./vm-test.sh ssh            # SSH into VM
./vm-test.sh web            # Open web interface
```

### 5. Cleanup
```bash
./vm-test.sh destroy        # Remove VM completely
```

## Development Use Cases

### 1. **Configuration Testing**
Test Apache, Dovecot, and application configurations before applying to production:
```bash
# Modify configs in ../config/
./vm-test.sh deploy         # Apply changes
./vm-test.sh test           # Validate
```

### 2. **Gallery Script Testing**
Test your jxqz.sh and jxqz-auto.sh scripts in a clean environment:
```bash
./vm-test.sh ssh
cd /home/steve/test-gallery
# Test gallery generation with sample images
```

### 3. **Disaster Recovery Testing**
Practice complete system reconstruction:
```bash
./vm-test.sh destroy        # Simulate total failure
./vm-test.sh start          # Fresh system
./vm-test.sh deploy         # Restore from configs
```

### 4. **Package Development**
Test Debian packages and installation procedures:
```bash
./vm-test.sh ssh
# Build and test .deb packages
sudo dpkg -i your-package.deb
```

### 5. **Performance Testing**
Test system performance and resource usage:
```bash
./vm-test.sh ssh
htop                        # Monitor resources
ab -n 1000 -c 10 http://localhost/  # Load testing
```

## Integration with Terraform

The VM testing environment integrates seamlessly with your Terraform configurations:

### Environment Selection
```bash
# Deploy to VirtualBox
terraform apply -var="environment=virtualbox"

# Deploy to production  
terraform apply -var="environment=production"
```

### Configuration Sources
Terraform automatically uses your retrieved configurations from:
- `../config/selective-configs-*/` - Apache and application configs
- `../config/dovecot-config-*/` - Email server configuration
- `../jxqz*.sh` - Gallery generation scripts

## Troubleshooting

### VM Won't Start
```bash
# Check VirtualBox status
VBoxManage list runningvms

# Reset networking
vagrant reload

# Complete reset
vagrant destroy -f && vagrant up
```

### SSH Connection Issues
```bash
# Check SSH key
ssh-add -l

# Manual SSH test
ssh -i ~/.ssh/id_rsa steve@192.168.56.10
```

### Service Problems
```bash
./vm-test.sh ssh
sudo systemctl status apache2
sudo systemctl restart apache2
sudo journalctl -u apache2 -f
```

### Terraform Issues
```bash
cd ../terraform
terraform init
terraform plan -var="environment=virtualbox"
```

## Benefits of This Approach

### 1. **Risk-Free Testing**
- Test changes without affecting production
- Validate configurations in identical environment
- Practice disaster recovery procedures

### 2. **Rapid Iteration**
- Quick VM creation/destruction cycle
- Automated deployment testing
- Immediate feedback on changes

### 3. **Documentation and Training**
- Serve as deployment documentation
- Train others on system setup
- Demonstrate Infrastructure as Code principles

### 4. **CI/CD Integration**
- Automate testing in CI pipelines
- Validate configurations before production
- Test multiple scenarios automatically

## Advanced Features

### Custom Provisioning
```bash
# Run advanced provisioning (Terraform, Docker, etc.)
vagrant provision --provision-with shell --provision-with shell
```

### Snapshot Management
```bash
# Create snapshot
VBoxManage snapshot jxqz-test-vm take "baseline"

# Restore snapshot
VBoxManage snapshot jxqz-test-vm restore "baseline"
```

### Multiple VMs
Modify `Vagrantfile` to create multiple VMs for complex testing scenarios.

## Production Parity

This testing environment maintains parity with your production server:
- **Same OS:** Debian 12 (Bookworm)
- **Same packages:** Apache2, PostgreSQL, Dovecot versions
- **Same configurations:** Uses your actual server configs
- **Same structure:** Identical directory layout and permissions

This ensures that successful testing translates directly to production deployments.

---

*This VirtualBox testing environment bridges your 30 years of hands-on systems administration experience with modern Infrastructure as Code practices, giving you the confidence to deploy changes safely while maintaining your proven operational expertise.*