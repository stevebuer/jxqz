#!/bin/bash

#
# vm-test.sh - VirtualBox testing environment management
# Automates VM creation, deployment testing, and cleanup
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $*"
}

success() {
    echo -e "${GREEN}✅${NC} $*"
}

warning() {
    echo -e "${YELLOW}⚠️${NC} $*"
}

error() {
    echo -e "${RED}❌${NC} $*"
}

usage() {
    cat << EOF
Usage: $0 [COMMAND]

VirtualBox testing environment management for JXQZ project.

COMMANDS:
    start       Start VirtualBox VM (create if needed)
    stop        Stop VirtualBox VM
    destroy     Destroy VirtualBox VM completely
    deploy      Deploy configurations to VM using Terraform
    test        Run deployment tests
    ssh         SSH into the VM
    web         Open web interface in browser
    status      Show VM and services status
    logs        Show service logs from VM
    clean       Clean up temporary files
    help        Show this help message

EXAMPLES:
    $0 start                 # Start VM
    $0 deploy                # Deploy configs to VM
    $0 test                  # Test deployment
    $0 ssh                   # SSH to VM
    $0 status                # Check everything

WORKFLOW:
    1. $0 start              # Create and start VM
    2. $0 deploy             # Deploy your configs
    3. $0 test               # Validate deployment
    4. $0 web                # Test in browser
    5. $0 destroy            # Clean up when done
EOF
}

check_prerequisites() {
    log "Checking prerequisites..."
    
    # Check VirtualBox
    if ! command -v VBoxManage &> /dev/null; then
        error "VirtualBox not found. Please install VirtualBox."
        exit 1
    fi
    
    # Check Vagrant
    if ! command -v vagrant &> /dev/null; then
        error "Vagrant not found. Please install Vagrant."
        exit 1
    fi
    
    # Check Terraform
    if ! command -v terraform &> /dev/null; then
        error "Terraform not found. Please install Terraform."
        exit 1
    fi
    
    success "Prerequisites check passed"
}

vm_start() {
    log "Starting VirtualBox VM..."
    cd "$SCRIPT_DIR"
    
    if vagrant status | grep -q "running"; then
        success "VM is already running"
    else
        log "Creating/starting VM..."
        vagrant up
        
        # Wait for SSH to be available
        log "Waiting for SSH to be available..."
        timeout=60
        while ! vagrant ssh -c "echo 'SSH ready'" &>/dev/null; do
            sleep 2
            timeout=$((timeout - 2))
            if [ $timeout -le 0 ]; then
                error "Timeout waiting for SSH"
                exit 1
            fi
        done
        
        success "VM started successfully"
        
        # Show connection info
        echo ""
        echo "VM Access Information:"
        echo "  SSH: vagrant ssh (from $SCRIPT_DIR)"
        echo "  IP:  192.168.56.10"
        echo "  Web: http://localhost:8080"
        echo ""
    fi
}

vm_stop() {
    log "Stopping VirtualBox VM..."
    cd "$SCRIPT_DIR"
    vagrant halt
    success "VM stopped"
}

vm_destroy() {
    log "Destroying VirtualBox VM..."
    cd "$SCRIPT_DIR"
    vagrant destroy -f
    success "VM destroyed"
}

deploy_to_vm() {
    log "Deploying configurations to VM using Terraform..."
    
    # Ensure VM is running
    if ! vagrant status | grep -q "running"; then
        log "VM not running, starting it first..."
        vm_start
    fi
    
    # Deploy with Terraform
    cd "$PROJECT_ROOT/terraform"
    
    log "Initializing Terraform..."
    terraform init
    
    log "Planning deployment..."
    terraform plan -var="environment=virtualbox"
    
    log "Applying deployment..."
    terraform apply -var="environment=virtualbox" -auto-approve
    
    success "Deployment completed"
    
    # Show access information
    echo ""
    echo "Deployment Results:"
    terraform output -json | jq -r '.virtualbox_info.value.test_sites[]' 2>/dev/null || echo "  Web: http://localhost:8080"
    echo ""
}

test_deployment() {
    log "Testing deployment..."
    
    # Test VM connectivity
    log "Testing VM SSH connectivity..."
    if ssh -o ConnectTimeout=5 steve@192.168.56.10 "echo 'SSH OK'" &>/dev/null; then
        success "SSH connectivity: OK"
    else
        error "SSH connectivity: FAILED"
    fi
    
    # Test web services
    log "Testing web services..."
    if curl -s http://localhost:8080 | grep -q "JXQZ\|Apache"; then
        success "Web service: OK"
    else
        warning "Web service: Check manually at http://localhost:8080"
    fi
    
    # Test services on VM
    log "Testing services on VM..."
    ssh steve@192.168.56.10 "
        echo 'Service Status:'
        sudo systemctl is-active apache2 && echo '  Apache2: Running' || echo '  Apache2: Not running'
        sudo systemctl is-active postgresql && echo '  PostgreSQL: Running' || echo '  PostgreSQL: Not running'
        sudo systemctl is-active dovecot && echo '  Dovecot: Running' || echo '  Dovecot: Not running'
    " 2>/dev/null || warning "Could not check VM services"
    
    success "Testing completed"
}

vm_ssh() {
    log "Connecting to VM via SSH..."
    cd "$SCRIPT_DIR"
    vagrant ssh
}

vm_web() {
    log "Opening web interface..."
    if command -v xdg-open &> /dev/null; then
        xdg-open http://localhost:8080
    elif command -v open &> /dev/null; then
        open http://localhost:8080
    else
        echo "Please open http://localhost:8080 in your browser"
    fi
}

vm_status() {
    log "Checking VM and services status..."
    
    cd "$SCRIPT_DIR"
    echo "VM Status:"
    vagrant status
    
    echo ""
    echo "Port Forwarding:"
    echo "  8080 -> 80   (HTTP)"
    echo "  8443 -> 443  (HTTPS)"
    echo "  1143 -> 143  (IMAP)"
    echo "  9993 -> 993  (IMAPS)"
    echo "  15432 -> 5432 (PostgreSQL)"
    
    if vagrant status | grep -q "running"; then
        echo ""
        echo "Storage Status:"
        ssh steve@192.168.56.10 "
            echo '  Disk Usage:'
            df -h | grep -E '(Filesystem|/dev/|tmpfs)' | head -5
            echo '  Mount Points:'
            mount | grep -E '/dev/sd|/web-content|/var/www' || echo '    No additional storage mounted'
            echo '  Block Devices:'
            lsblk | head -10
            
            echo ''
            echo '  Storage Layout:'
            if [ -d /web-content ]; then
                echo '    ✅ Enhanced Storage Layout Detected'
                echo '    📁 Web content volume: /web-content'
                echo '    🔗 Compatibility symlinks:'
                ls -la /var/www/ | grep '=>' | head -5 || echo '    No symlinks found'
                echo '    📊 Enhanced volume usage:'
                du -sh /web-content/* 2>/dev/null | head -5 || echo '    No content yet'
            else
                echo '    📝 Standard Storage Layout'
                echo '    📁 Traditional paths: /var/www/, ~/public_html'
            fi
        " 2>/dev/null || warning "Could not check storage"
        
        echo ""
        echo "Services on VM:"
        ssh steve@192.168.56.10 "
            sudo systemctl status apache2 --no-pager -l || true
            echo ''
            sudo systemctl status postgresql --no-pager -l || true
            echo ''
            sudo systemctl status dovecot --no-pager -l || true
        " 2>/dev/null || warning "Could not check services"
    fi
}

vm_logs() {
    log "Showing service logs from VM..."
    if ! vagrant status | grep -q "running"; then
        error "VM is not running"
        exit 1
    fi
    
    ssh steve@192.168.56.10 "
        echo '=== Apache Logs ==='
        sudo tail -20 /var/log/apache2/error.log
        echo ''
        echo '=== PostgreSQL Logs ==='
        sudo tail -20 /var/log/postgresql/postgresql-*-main.log
        echo ''
        echo '=== System Logs ==='
        sudo journalctl -u apache2 -u postgresql -u dovecot --no-pager -n 20
    " 2>/dev/null || warning "Could not retrieve logs"
}

clean_up() {
    log "Cleaning up temporary files..."
    cd "$PROJECT_ROOT"
    
    # Clean Terraform state
    find terraform -name "*.tfstate*" -delete 2>/dev/null || true
    find terraform -name ".terraform" -type d -exec rm -rf {} + 2>/dev/null || true
    
    # Clean any temp files
    find . -name "*.tmp" -delete 2>/dev/null || true
    
    success "Cleanup completed"
}

# Main script logic
case "${1:-help}" in
    start)
        check_prerequisites
        vm_start
        ;;
    stop)
        vm_stop
        ;;
    destroy)
        vm_destroy
        clean_up
        ;;
    deploy)
        check_prerequisites
        deploy_to_vm
        ;;
    test)
        test_deployment
        ;;
    ssh)
        vm_ssh
        ;;
    web)
        vm_web
        ;;
    status)
        vm_status
        ;;
    logs)
        vm_logs
        ;;
    clean)
        clean_up
        ;;
    help|--help|-h)
        usage
        ;;
    *)
        error "Unknown command: $1"
        echo ""
        usage
        exit 1
        ;;
esac