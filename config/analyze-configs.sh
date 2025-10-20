#!/bin/bash

#
# analyze-configs.sh - Analyze retrieved server configurations
# Helps identify custom configurations for Terraform module development
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
    cat << EOF
Usage: $0 [CONFIG_BACKUP_DIR]

Analyze retrieved server configurations to identify customizations
and generate documentation for Terraform module development.

ARGUMENTS:
    CONFIG_BACKUP_DIR   Directory containing retrieved configurations
                       (default: latest server-configs-* directory)

EXAMPLES:
    $0                                    # Use latest backup
    $0 server-configs-20251020-143022     # Use specific backup

OUTPUT:
    - Configuration analysis report
    - List of customizations vs defaults
    - Recommendations for Terraform modules
    - Security findings and recommendations
EOF
}

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

# Find backup directory
if [[ $# -eq 1 ]]; then
    BACKUP_DIR="$SCRIPT_DIR/$1"
elif [[ $# -eq 0 ]]; then
    # Find latest backup directory
    BACKUP_DIR=$(find "$SCRIPT_DIR" -maxdepth 1 -type d -name "server-configs-*" | sort | tail -1)
    if [[ -z "$BACKUP_DIR" ]]; then
        echo "Error: No server configuration backup found."
        echo "Run retrieve-server-configs.sh first, or specify backup directory."
        exit 1
    fi
else
    usage
    exit 1
fi

if [[ ! -d "$BACKUP_DIR" ]]; then
    echo "Error: Backup directory not found: $BACKUP_DIR"
    exit 1
fi

ANALYSIS_FILE="$BACKUP_DIR/CONFIGURATION_ANALYSIS.md"

log "Analyzing configurations in: $BACKUP_DIR"
log "Analysis report: $ANALYSIS_FILE"

# Create analysis report
cat > "$ANALYSIS_FILE" << 'EOF'
# Server Configuration Analysis Report

This document analyzes the retrieved server configurations to identify customizations and guide Terraform module development.

## Executive Summary

### Custom Configurations Found
- [ ] Apache virtual hosts
- [ ] SSL/TLS certificates
- [ ] Email server configuration
- [ ] Security settings (fail2ban, ufw)
- [ ] Custom scripts and tools
- [ ] Cron jobs and scheduled tasks

### Terraform Module Recommendations
Based on the analysis below, consider creating these Terraform modules:
- [ ] `apache-webserver` - Apache configuration and virtual hosts
- [ ] `mail-server` - Dovecot/Postfix email setup
- [ ] `security-baseline` - Firewall, fail2ban, basic hardening
- [ ] `ssl-certificates` - Let's Encrypt or custom certificate management

---

EOF

# Analyze Apache Configuration
if [[ -d "$BACKUP_DIR/apache2" ]]; then
    cat >> "$ANALYSIS_FILE" << 'EOF'
## Apache Configuration Analysis

### Virtual Hosts
EOF
    
    if [[ -d "$BACKUP_DIR/apache2/etc/apache2/sites-available" ]]; then
        echo "" >> "$ANALYSIS_FILE"
        echo "Found virtual host configurations:" >> "$ANALYSIS_FILE"
        echo '```' >> "$ANALYSIS_FILE"
        find "$BACKUP_DIR/apache2/etc/apache2/sites-available" -name "*.conf" | while read site; do
            echo "$(basename "$site"):" >> "$ANALYSIS_FILE"
            grep -E "ServerName|ServerAlias|DocumentRoot|Directory" "$site" 2>/dev/null | sed 's/^/  /' >> "$ANALYSIS_FILE"
            echo "" >> "$ANALYSIS_FILE"
        done
        echo '```' >> "$ANALYSIS_FILE"
    fi
    
    cat >> "$ANALYSIS_FILE" << 'EOF'

### Enabled Modules
EOF
    
    if [[ -d "$BACKUP_DIR/apache2/etc/apache2/mods-enabled" ]]; then
        echo '```' >> "$ANALYSIS_FILE"
        ls "$BACKUP_DIR/apache2/etc/apache2/mods-enabled"/*.load 2>/dev/null | xargs -r basename -s .load | sort >> "$ANALYSIS_FILE"
        echo '```' >> "$ANALYSIS_FILE"
    fi
    
    cat >> "$ANALYSIS_FILE" << 'EOF'

### Custom Configuration Files
EOF
    
    echo '```' >> "$ANALYSIS_FILE"
    find "$BACKUP_DIR/apache2" -name "*.conf" -not -path "*/sites-available/*" -not -path "*/sites-enabled/*" | while read conf; do
        rel_path=${conf#$BACKUP_DIR/apache2/}
        echo "$rel_path"
        
        # Check for customizations (non-default settings)
        if [[ -f "$conf" ]]; then
            custom_lines=$(grep -v "^#" "$conf" | grep -v "^$" | wc -l)
            if [[ $custom_lines -gt 0 ]]; then
                echo "  → $custom_lines lines of configuration"
            fi
        fi
    done >> "$ANALYSIS_FILE"
    echo '```' >> "$ANALYSIS_FILE"
fi

# Analyze SSL/TLS
if [[ -d "$BACKUP_DIR/ssl" ]]; then
    cat >> "$ANALYSIS_FILE" << 'EOF'

## SSL/TLS Certificate Analysis

### Certificate Files Found
EOF
    
    echo '```' >> "$ANALYSIS_FILE"
    find "$BACKUP_DIR/ssl" -name "*.crt" -o -name "*.pem" | while read cert; do
        rel_path=${cert#$BACKUP_DIR/ssl/}
        echo "$rel_path"
        
        # Try to get certificate info
        if command -v openssl >/dev/null 2>&1; then
            subject=$(openssl x509 -in "$cert" -noout -subject 2>/dev/null | sed 's/subject=//' || echo "Could not parse")
            expiry=$(openssl x509 -in "$cert" -noout -enddate 2>/dev/null | sed 's/notAfter=//' || echo "Could not parse")
            echo "  Subject: $subject"
            echo "  Expires: $expiry"
        fi
        echo ""
    done >> "$ANALYSIS_FILE"
    echo '```' >> "$ANALYSIS_FILE"
fi

# Analyze Services
if [[ -d "$BACKUP_DIR/services" ]]; then
    cat >> "$ANALYSIS_FILE" << 'EOF'

## Service Configuration Analysis

### Configured Services
EOF
    
    echo '```' >> "$ANALYSIS_FILE"
    for service_dir in "$BACKUP_DIR/services"/*; do
        if [[ -d "$service_dir" ]]; then
            service_name=$(basename "$service_dir")
            echo "$service_name:"
            
            # Count configuration files
            conf_count=$(find "$service_dir" -name "*.conf" -o -name "*.cfg" | wc -l)
            echo "  → $conf_count configuration files"
            
            # List main config files
            find "$service_dir" -maxdepth 2 -name "*.conf" | head -3 | while read conf; do
                rel_path=${conf#$service_dir/}
                echo "    - $rel_path"
            done
            echo ""
        fi
    done >> "$ANALYSIS_FILE"
    echo '```' >> "$ANALYSIS_FILE"
fi

# Analyze Scripts
if [[ -d "$BACKUP_DIR/scripts" ]]; then
    cat >> "$ANALYSIS_FILE" << 'EOF'

## Custom Scripts Analysis

### Found Scripts
EOF
    
    echo '```' >> "$ANALYSIS_FILE"
    find "$BACKUP_DIR/scripts" -type f -executable 2>/dev/null | while read script; do
        rel_path=${script#$BACKUP_DIR/scripts/}
        echo "$rel_path"
        
        # Get first comment line as description
        first_comment=$(head -10 "$script" | grep "^#" | grep -v "^#!/" | head -1 | sed 's/^# *//' 2>/dev/null || echo "")
        if [[ -n "$first_comment" ]]; then
            echo "  → $first_comment"
        fi
    done >> "$ANALYSIS_FILE"
    echo '```' >> "$ANALYSIS_FILE"
fi

# Analyze Cron Jobs
if [[ -d "$BACKUP_DIR/cron" ]]; then
    cat >> "$ANALYSIS_FILE" << 'EOF'

## Scheduled Tasks Analysis

### Cron Jobs
EOF
    
    echo '```' >> "$ANALYSIS_FILE"
    find "$BACKUP_DIR/cron" -type f | while read cronfile; do
        if [[ -s "$cronfile" ]]; then
            rel_path=${cronfile#$BACKUP_DIR/cron/}
            echo "$rel_path:"
            grep -v "^#" "$cronfile" | grep -v "^$" | sed 's/^/  /' 2>/dev/null || true
            echo ""
        fi
    done >> "$ANALYSIS_FILE"
    echo '```' >> "$ANALYSIS_FILE"
fi

# Generate Terraform recommendations
cat >> "$ANALYSIS_FILE" << 'EOF'

## Terraform Module Recommendations

### 1. Apache Web Server Module (`terraform/modules/apache/`)
**Purpose:** Configure Apache web server with custom virtual hosts and modules

**Key Resources:**
- Virtual host configuration files
- SSL certificate management
- Module enablement
- Security headers and configurations

**Variables to Extract:**
- Domain names from virtual hosts
- Document root paths
- SSL certificate paths
- Required Apache modules

### 2. Security Baseline Module (`terraform/modules/security/`)
**Purpose:** Implement security configurations (firewall, fail2ban, etc.)

**Key Resources:**
- UFW firewall rules
- fail2ban configuration
- SSH hardening
- Log monitoring setup

### 3. Mail Server Module (`terraform/modules/mail/`)
**Purpose:** Configure email services (Dovecot, Postfix)

**Key Resources:**
- IMAP/POP3 configuration
- SMTP relay setup
- User authentication
- SSL/TLS for mail services

### 4. User Environment Module (`terraform/modules/user-env/`)
**Purpose:** Set up user accounts and development environment

**Key Resources:**
- User account creation
- SSH key management
- Shell configuration
- Development tools installation

## Next Steps

1. **Review Configurations:**
   - Examine each configuration file for customizations
   - Document any non-standard settings
   - Identify dependencies between services

2. **Create Terraform Modules:**
   - Start with the Apache module (highest priority)
   - Use retrieved configurations as templates
   - Implement variables for environment-specific values

3. **Test Deployment:**
   - Create a test environment using Terraform
   - Validate that configurations work correctly
   - Compare with production environment

4. **Document Migration:**
   - Update disaster recovery procedures
   - Create runbooks for common operations
   - Document rollback procedures

## Security Considerations

- [ ] Review all configuration files for hardcoded credentials
- [ ] Implement proper secret management in Terraform
- [ ] Ensure SSL certificates are managed securely
- [ ] Set up monitoring and alerting for security events
- [ ] Document incident response procedures

## Automation Opportunities

Based on the retrieved configurations, consider automating:
- SSL certificate renewal
- Log rotation and cleanup
- Security updates and patching
- Backup verification
- Performance monitoring
EOF

log "✅ Configuration analysis completed!"
log "📄 Report generated: $ANALYSIS_FILE"
log ""
log "🔍 Review the analysis report to understand your current configuration"
log "🏗️  Use the recommendations to plan your Terraform module development"
log "🔒 Pay attention to the security considerations section"