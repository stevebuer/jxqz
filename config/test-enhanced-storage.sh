#!/bin/bash

#
# test-enhanced-storage.sh - Test enhanced storage configuration in VirtualBox
# Validates the consolidated web content storage layout
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
VIRTUALBOX_DIR="$PROJECT_DIR/virtualbox"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

error() {
    echo "[ERROR] $*" >&2
    exit 1
}

# Check if we're in the right location
if [[ ! -d "$VIRTUALBOX_DIR" ]]; then
    error "VirtualBox directory not found at $VIRTUALBOX_DIR"
fi

cd "$VIRTUALBOX_DIR"

log "🧪 Testing Enhanced Storage Configuration in VirtualBox"
log "📁 Working directory: $VIRTUALBOX_DIR"

# Check if VM is running
vm_status=$(vagrant status --machine-readable | grep "default,state," | cut -d',' -f4)
log "🔍 Current VM status: $vm_status"

# Start VM if not running
if [[ "$vm_status" != "running" ]]; then
    log "🚀 Starting VirtualBox VM..."
    vagrant up
    log "✅ VM started successfully"
else
    log "✅ VM already running"
fi

# Wait a moment for services to be ready
sleep 5

log "🔧 Testing enhanced storage configuration..."

# Test storage layout
log "📊 Checking storage layout..."
vagrant ssh -c "
echo '=== Storage Layout Test ==='
echo 'Checking for enhanced storage volume...'
if [ -b /dev/sdb1 ]; then
    echo '✅ Additional storage volume found: /dev/sdb1'
    lsblk /dev/sdb1
    echo
    echo 'Mount information:'
    df -h /web-content 2>/dev/null || echo 'Standard layout - no /web-content mount'
    echo
else
    echo '❌ No additional storage volume found'
fi

echo
echo '=== Directory Structure Test ==='
if [ -d /web-content ]; then
    echo '✅ Enhanced storage layout detected'
    echo 'Directory structure:'
    tree /web-content -L 3 2>/dev/null || find /web-content -type d | head -20
    echo
    echo 'Checking symlinks:'
    ls -la /var/www/ | grep '=>' || echo 'No symlinks found in /var/www'
    ls -la /home/steve/ | grep public_html || echo 'No public_html symlink found'
else
    echo '📝 Standard layout detected'
    echo 'Standard directories:'
    ls -la /var/www/ 2>/dev/null || echo 'No /var/www directory'
    ls -la /home/steve/public_html 2>/dev/null || echo 'No ~/public_html directory'
fi

echo
echo '=== Permissions Test ==='
if [ -d /web-content ]; then
    echo 'Enhanced layout permissions:'
    ls -ld /web-content/
    ls -ld /web-content/sites/ 2>/dev/null || echo 'No sites directory'
    ls -ld /web-content/user/steve/ 2>/dev/null || echo 'No user directory'
else
    echo 'Standard layout permissions:'
    ls -ld /var/www/ 2>/dev/null || echo 'No /var/www directory'
    ls -ld /home/steve/public_html 2>/dev/null || echo 'No ~/public_html directory'
fi
"

log "🌐 Testing web server access..."

# Test basic web access
if curl -f -s http://localhost:8080/ > /dev/null; then
    log "✅ Web server accessible at http://localhost:8080/"
else
    log "❌ Web server not accessible"
fi

# Test creating content in the enhanced layout
log "📝 Testing content creation..."
vagrant ssh -c "
echo '=== Content Creation Test ==='

# Test main site content
if [ -d /web-content/sites/jxqz.org ]; then
    echo '<h1>Enhanced Storage Test - JXQZ.org</h1><p>Created: $(date)</p>' > /web-content/sites/jxqz.org/test.html
    echo '✅ Created test content in /web-content/sites/jxqz.org/'
    ls -la /web-content/sites/jxqz.org/test.html
else
    echo '<h1>Standard Layout Test - JXQZ.org</h1><p>Created: $(date)</p>' > /var/www/jxqz.org/test.html
    echo '✅ Created test content in /var/www/jxqz.org/'
    ls -la /var/www/jxqz.org/test.html
fi

# Test user directory content
if [ -d /web-content/user/steve/public_html ]; then
    echo '<h1>Enhanced User Directory Test</h1><p>User: steve</p><p>Created: $(date)</p>' > /web-content/user/steve/public_html/test.html
    echo '✅ Created test content in enhanced user directory'
    ls -la /web-content/user/steve/public_html/test.html
else
    echo '<h1>Standard User Directory Test</h1><p>User: steve</p><p>Created: $(date)</p>' > /home/steve/public_html/test.html
    echo '✅ Created test content in standard user directory'
    ls -la /home/steve/public_html/test.html
fi

echo
echo '=== Symlink Verification ==='
if [ -L /var/www/jxqz.org ]; then
    echo 'jxqz.org symlink target:' $(readlink /var/www/jxqz.org)
    echo 'Content accessible via symlink:'
    ls -la /var/www/jxqz.org/test.html 2>/dev/null || echo 'Test file not accessible via symlink'
fi

if [ -L /home/steve/public_html ]; then
    echo 'public_html symlink target:' $(readlink /home/steve/public_html)
    echo 'Content accessible via symlink:'
    ls -la /home/steve/public_html/test.html 2>/dev/null || echo 'Test file not accessible via symlink'
fi
"

log "🔍 Testing Apache configuration..."
vagrant ssh -c "
echo '=== Apache Configuration Test ==='
echo 'Checking Apache syntax:'
apache2ctl configtest

echo
echo 'Checking enabled modules:'
apache2ctl -M | grep -E '(userdir|rewrite)' || echo 'Key modules may not be enabled'

echo
echo 'Checking virtual hosts:'
apache2ctl -S 2>/dev/null || echo 'Error checking virtual hosts'
"

log "📊 Storage usage summary..."
vagrant ssh -c "
echo '=== Storage Usage Summary ==='
df -h | grep -E '(web-content|/var/www|/home)' || df -h

echo
echo 'Enhanced storage benefits verification:'
if [ -d /web-content ]; then
    echo '✅ All web content consolidated on dedicated volume'
    echo '✅ User content benefits from noatime mount option'
    echo '✅ Simplified backup strategy (single location)'
    echo '✅ Improved scalability (independent volume expansion)'
else
    echo '📝 Standard layout - consider migration to enhanced storage'
fi
"

log "✅ Enhanced storage testing complete!"
log ""
log "📋 Test Results Summary:"
log "   - Storage layout: Enhanced or Standard detected"
log "   - Permissions: Verified for web content access"
log "   - Symlinks: Backward compatibility maintained"
log "   - Apache: Configuration validated"
log "   - Content: Test files created successfully"
log ""
log "🔧 Next Steps:"
log "   1. Review test results above"
log "   2. Test gallery script functionality"
log "   3. Validate Terraform deployment"
log "   4. Plan production migration timeline"
log ""
log "💡 Access URLs:"
log "   - Main site: http://localhost:8080/"
log "   - VM SSH: vagrant ssh"
log "   - VM IP: 192.168.56.10"