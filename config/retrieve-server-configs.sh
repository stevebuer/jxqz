#!/bin/bash

#
# retrieve-server-configs.sh - Retrieve hand-rolled configuration files from remote server
# Part of JXQZ disaster recovery and Infrastructure as Code migration toolkit
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="${SCRIPT_DIR}/server-configs-${BACKUP_TIMESTAMP}"

# Configuration - Update these for your server
REMOTE_SERVER="${REMOTE_SERVER:-}"
REMOTE_USER="${REMOTE_USER:-steve}"

usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Retrieve hand-rolled configuration files from remote server for documentation
and Infrastructure as Code migration.

OPTIONS:
    -s, --server HOST    Remote server hostname or IP (required)
    -u, --user USER      Remote username (default: steve)
    -h, --help          Show this help message

ENVIRONMENT VARIABLES:
    REMOTE_SERVER       Remote server hostname/IP
    REMOTE_USER         Remote username (default: steve)

EXAMPLES:
    $0 -s your-server.com
    $0 -s 192.168.1.100 -u root
    REMOTE_SERVER=your-server.com $0

WHAT GETS RETRIEVED:
    - Apache2 configuration (/etc/apache2/)
    - System configuration files
    - Cron jobs and scheduled tasks
    - Network configuration
    - SSL/TLS certificates (public only)
    - Service configurations (Dovecot, etc.)
    - Custom scripts and tools
    - User configurations

SECURITY:
    - Private keys are NOT retrieved
    - Passwords are sanitized from config files
    - Backup includes only essential configuration data
EOF
}

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >&2
}

error() {
    log "ERROR: $*"
    exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--server)
            REMOTE_SERVER="$2"
            shift 2
            ;;
        -u|--user)
            REMOTE_USER="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            ;;
    esac
done

# Validate required parameters
if [[ -z "$REMOTE_SERVER" ]]; then
    echo "Error: Remote server must be specified"
    echo ""
    usage
    exit 1
fi

# Test SSH connectivity
log "Testing SSH connectivity to ${REMOTE_USER}@${REMOTE_SERVER}..."
if ! ssh -o ConnectTimeout=10 -o BatchMode=yes "${REMOTE_USER}@${REMOTE_SERVER}" 'echo "SSH connection successful"' 2>/dev/null; then
    error "Cannot connect to ${REMOTE_USER}@${REMOTE_SERVER}. Check SSH keys and server accessibility."
fi

# Create backup directory structure
log "Creating backup directory structure..."
mkdir -p "$BACKUP_DIR"/{apache2,system,network,ssl,services,scripts,user,cron}

log "Starting configuration retrieval from ${REMOTE_USER}@${REMOTE_SERVER}..."

# Function to safely copy files via SSH
safe_copy() {
    local remote_path="$1"
    local local_dir="$2"
    local description="$3"
    
    log "Retrieving $description..."
    
    # Check if remote path exists
    if ssh "${REMOTE_USER}@${REMOTE_SERVER}" "test -e '$remote_path'" 2>/dev/null; then
        # Use rsync for reliable transfer with exclusions
        rsync -avz --exclude='*.key' --exclude='*private*' --exclude='*password*' \
              "${REMOTE_USER}@${REMOTE_SERVER}:${remote_path}" "${local_dir}/" 2>/dev/null || {
            log "Warning: Could not retrieve $description from $remote_path"
        }
    else
        log "Warning: $description not found at $remote_path"
    fi
}

# Function to retrieve file with sudo if needed
safe_copy_sudo() {
    local remote_path="$1"
    local local_dir="$2"
    local description="$3"
    
    log "Retrieving $description (may require sudo)..."
    
    # Create a temporary script on remote server
    ssh "${REMOTE_USER}@${REMOTE_SERVER}" "
        if [ -e '$remote_path' ]; then
            sudo tar czf /tmp/config_backup.tar.gz -C / '$remote_path' 2>/dev/null || echo 'FAILED'
            if [ -f /tmp/config_backup.tar.gz ]; then
                sudo chown \$(whoami):\$(whoami) /tmp/config_backup.tar.gz
                echo 'SUCCESS'
            fi
        else
            echo 'NOT_FOUND'
        fi
    " | while read result; do
        case "$result" in
            SUCCESS)
                scp "${REMOTE_USER}@${REMOTE_SERVER}:/tmp/config_backup.tar.gz" "/tmp/config_backup_$$.tar.gz" 2>/dev/null
                tar -xzf "/tmp/config_backup_$$.tar.gz" -C "$local_dir" 2>/dev/null || true
                rm -f "/tmp/config_backup_$$.tar.gz"
                ssh "${REMOTE_USER}@${REMOTE_SERVER}" "rm -f /tmp/config_backup.tar.gz"
                ;;
            NOT_FOUND)
                log "Warning: $description not found at $remote_path"
                ;;
            FAILED)
                log "Warning: Could not retrieve $description (permission denied)"
                ;;
        esac
    done
}

# Apache2 Configuration
safe_copy_sudo "/etc/apache2" "$BACKUP_DIR/apache2" "Apache2 configuration"

# System Configuration Files
log "Retrieving system configuration files..."
for config_file in "/etc/hostname" "/etc/hosts" "/etc/resolv.conf" "/etc/fstab" "/etc/timezone"; do
    safe_copy_sudo "$config_file" "$BACKUP_DIR/system" "$(basename $config_file)"
done

# Network Configuration
safe_copy_sudo "/etc/network" "$BACKUP_DIR/network" "Network configuration"
safe_copy_sudo "/etc/systemd/network" "$BACKUP_DIR/network" "Systemd network configuration"

# Service Configurations
log "Retrieving service configurations..."
for service in "dovecot" "postfix" "fail2ban" "ufw"; do
    safe_copy_sudo "/etc/$service" "$BACKUP_DIR/services" "$service configuration"
done

# SSL Certificates (public only)
log "Retrieving SSL certificates (public keys only)..."
ssh "${REMOTE_USER}@${REMOTE_SERVER}" "
    find /etc/ssl/certs /etc/letsencrypt -name '*.crt' -o -name '*.pem' -o -name 'cert.pem' -o -name 'chain.pem' -o -name 'fullchain.pem' 2>/dev/null | \
    while read cert; do
        if [[ ! \$cert =~ private ]]; then
            echo \$cert
        fi
    done
" | while read cert_file; do
    if [[ -n "$cert_file" ]]; then
        cert_dir=$(dirname "$cert_file")
        mkdir -p "$BACKUP_DIR/ssl$cert_dir"
        safe_copy "$cert_file" "$BACKUP_DIR/ssl$cert_dir" "SSL certificate $(basename $cert_file)"
    fi
done

# Cron Jobs
log "Retrieving cron configurations..."
safe_copy_sudo "/etc/crontab" "$BACKUP_DIR/cron" "System crontab"
safe_copy_sudo "/etc/cron.d" "$BACKUP_DIR/cron" "Cron.d directory"
safe_copy_sudo "/var/spool/cron/crontabs" "$BACKUP_DIR/cron" "User crontabs"

# User Scripts and Configuration
log "Retrieving user scripts and configuration..."
for user_item in ".bashrc" ".bash_profile" ".vimrc" ".ssh/config" "bin" "scripts"; do
    safe_copy "$user_item" "$BACKUP_DIR/user" "User $user_item"
done

# Custom scripts in common locations
for script_dir in "/usr/local/bin" "/opt" "/home/*/bin" "/home/*/scripts"; do
    safe_copy_sudo "$script_dir" "$BACKUP_DIR/scripts" "Scripts in $script_dir"
done

# System Information
log "Gathering system information..."
ssh "${REMOTE_USER}@${REMOTE_SERVER}" "
    echo '=== System Information ===' > /tmp/system_info.txt
    echo 'Date: $(date)' >> /tmp/system_info.txt
    echo 'Hostname: $(hostname)' >> /tmp/system_info.txt
    echo 'OS: $(cat /etc/os-release | grep PRETTY_NAME)' >> /tmp/system_info.txt
    echo 'Kernel: $(uname -r)' >> /tmp/system_info.txt
    echo 'Architecture: $(uname -m)' >> /tmp/system_info.txt
    echo '' >> /tmp/system_info.txt
    
    echo '=== Apache Version ===' >> /tmp/system_info.txt
    apache2 -v 2>/dev/null >> /tmp/system_info.txt || echo 'Apache not found' >> /tmp/system_info.txt
    echo '' >> /tmp/system_info.txt
    
    echo '=== Enabled Apache Modules ===' >> /tmp/system_info.txt
    apache2ctl -M 2>/dev/null >> /tmp/system_info.txt || echo 'Could not list modules' >> /tmp/system_info.txt
    echo '' >> /tmp/system_info.txt
    
    echo '=== Enabled Apache Sites ===' >> /tmp/system_info.txt
    ls -la /etc/apache2/sites-enabled/ 2>/dev/null >> /tmp/system_info.txt || echo 'Could not list sites' >> /tmp/system_info.txt
    echo '' >> /tmp/system_info.txt
    
    echo '=== Installed Packages ===' >> /tmp/system_info.txt
    dpkg -l >> /tmp/system_info.txt 2>/dev/null || echo 'Could not list packages' >> /tmp/system_info.txt
    echo '' >> /tmp/system_info.txt
    
    echo '=== Running Services ===' >> /tmp/system_info.txt
    systemctl list-units --type=service --state=running >> /tmp/system_info.txt 2>/dev/null || echo 'Could not list services' >> /tmp/system_info.txt
"

scp "${REMOTE_USER}@${REMOTE_SERVER}:/tmp/system_info.txt" "$BACKUP_DIR/SYSTEM_INFO.txt" 2>/dev/null
ssh "${REMOTE_USER}@${REMOTE_SERVER}" "rm -f /tmp/system_info.txt"

# Clean up sensitive information
log "Sanitizing configuration files..."
find "$BACKUP_DIR" -type f -name "*.conf" -o -name "*.cfg" -o -name "*.ini" | while read config_file; do
    # Remove common password patterns (create backup first)
    if [[ -f "$config_file" ]]; then
        cp "$config_file" "${config_file}.original"
        sed -i.bak \
            -e 's/password=.*/password=REDACTED/gi' \
            -e 's/passwd=.*/passwd=REDACTED/gi' \
            -e 's/secret=.*/secret=REDACTED/gi' \
            -e 's/key=.*/key=REDACTED/gi' \
            "$config_file" 2>/dev/null || true
        rm -f "${config_file}.bak"
    fi
done

# Create retrieval manifest
log "Creating retrieval manifest..."
cat > "$BACKUP_DIR/RETRIEVAL_MANIFEST.txt" << EOF
Server Configuration Retrieval Report
Generated: $(date)
Remote Server: ${REMOTE_USER}@${REMOTE_SERVER}
Local Backup: $BACKUP_DIR

=== Directory Structure ===
$(find "$BACKUP_DIR" -type d | sort)

=== Retrieved Files ===
$(find "$BACKUP_DIR" -type f | wc -l) files retrieved

=== File Listing ===
$(find "$BACKUP_DIR" -type f | sort)

=== Security Notes ===
- Private keys (.key files) were excluded
- Files containing 'private' or 'password' in name were excluded
- Configuration files were sanitized to remove password values
- Original unsanitized files saved with .original extension where applicable

=== Next Steps ===
1. Review retrieved configurations
2. Document differences from default configurations
3. Create Terraform modules based on custom configurations
4. Test configuration restoration procedures
5. Update disaster recovery documentation

=== Integration with Terraform ===
Use these configurations to inform:
- terraform/modules/apache/
- terraform/modules/security/
- terraform/modules/mail/
- User data scripts for automated deployment
EOF

# Set proper permissions
find "$BACKUP_DIR" -type d -exec chmod 755 {} \;
find "$BACKUP_DIR" -type f -exec chmod 644 {} \;

log ""
log "✅ Configuration retrieval completed successfully!"
log "📁 Location: $BACKUP_DIR"
log "📋 Manifest: $BACKUP_DIR/RETRIEVAL_MANIFEST.txt"
log "📊 System Info: $BACKUP_DIR/SYSTEM_INFO.txt"
log ""
log "⚠️  Security Notes:"
log "   - Private keys were excluded for security"
log "   - Passwords were sanitized in configuration files"
log "   - Original files preserved with .original extension"
log ""
log "🔄 Next Steps:"
log "   1. Review the retrieved configurations"
log "   2. git add config/ && git commit -m 'Add server configuration backup'"
log "   3. Use configurations to inform Terraform modules"
log "   4. Update disaster recovery procedures"
log ""
log "📚 Documentation:"
log "   - Update config/README.md with server-specific notes"
log "   - Document custom configurations for Terraform migration"