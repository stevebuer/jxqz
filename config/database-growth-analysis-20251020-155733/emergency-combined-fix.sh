#!/bin/bash

#
# emergency-combined-fix.sh - Fix both Docker AND PostgreSQL space issues
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log() {
    echo "[$(date '+%H:%M:%S')] $*"
}

log "🚨 Combined Emergency Fix: Docker + PostgreSQL"
log "This will move both Docker and PostgreSQL off the root volume"
log ""
read -p "Continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log "Cancelled by user"
    exit 0
fi

# Run PostgreSQL migration first
log "Step 1: PostgreSQL Migration"
if [[ -f "$SCRIPT_DIR/emergency-postgres-migration.sh" ]]; then
    chmod +x "$SCRIPT_DIR/emergency-postgres-migration.sh"
    sudo "$SCRIPT_DIR/emergency-postgres-migration.sh"
else
    log "❌ PostgreSQL migration script not found"
fi

echo ""
log "Step 2: Docker Migration" 
if [[ -f "$SCRIPT_DIR/../emergency-docker-space.sh" ]]; then
    chmod +x "$SCRIPT_DIR/../emergency-docker-space.sh"
    sudo "$SCRIPT_DIR/../emergency-docker-space.sh"
else
    log "❌ Docker migration script not found"
fi

log "✅ Combined emergency fix completed!"
log "Both Docker and PostgreSQL moved off root volume"
