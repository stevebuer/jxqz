#!/bin/bash

#
# provision-terraform.sh - Advanced VM provisioning for Terraform testing
# This script sets up the VM to be managed by Terraform
#

set -euo pipefail

echo "=== Advanced Terraform Provisioning ==="

# Install Terraform (latest version)
if ! command -v terraform &> /dev/null; then
    echo "Installing Terraform..."
    wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
    apt update
    apt install -y terraform
fi

# Install Ansible (for configuration management)
if ! command -v ansible &> /dev/null; then
    echo "Installing Ansible..."
    apt install -y ansible
fi

# Install Docker (for container testing)
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt update
    apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    usermod -aG docker vagrant
    usermod -aG docker steve
fi

# Configure PostgreSQL for testing
echo "Configuring PostgreSQL..."
sudo -u postgres createuser -s steve 2>/dev/null || echo "User steve already exists in PostgreSQL"
sudo -u postgres createdb jxqz_test -O steve 2>/dev/null || echo "Database jxqz_test already exists"

# Create Python virtual environment for Flask applications
echo "Setting up Python environment..."
sudo -u steve python3 -m venv /home/steve/venv
sudo -u steve /home/steve/venv/bin/pip install --upgrade pip
sudo -u steve /home/steve/venv/bin/pip install flask psycopg2-binary requests

# Copy SSH keys for Terraform remote-exec
echo "Setting up SSH for Terraform..."
mkdir -p /home/steve/.ssh
cp /home/vagrant/.ssh/authorized_keys /home/steve/.ssh/ 2>/dev/null || true
chown -R steve:steve /home/steve/.ssh
chmod 700 /home/steve/.ssh
chmod 600 /home/steve/.ssh/authorized_keys 2>/dev/null || true

# Allow passwordless sudo for steve (like production)
echo "steve ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/steve

# Create directory structure for Terraform state
mkdir -p /home/steve/terraform-state
chown steve:steve /home/steve/terraform-state

echo ""
echo "=== Advanced provisioning complete ==="
echo "Services available:"
echo "- Terraform: $(terraform version | head -1)"
echo "- Ansible: $(ansible --version | head -1)"
echo "- Docker: $(docker --version)"
echo "- PostgreSQL: Running on port 5432"
echo ""
echo "Ready for Terraform deployment testing!"