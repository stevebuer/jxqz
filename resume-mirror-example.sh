#!/bin/bash

#
# resume-mirror-example.sh - Enhanced rsync with better resume capabilities
#

# Enhanced rsync command with maximum resume reliability
rsync_enhanced() {
    local src="$1"
    local dest="$2"
    local desc="$3"
    
    echo "🔄 Syncing $desc..."
    
    # Enhanced flags for maximum resume capability
    rsync \
        --archive \
        --verbose \
        --compress \
        --progress \
        --stats \
        --partial \
        --partial-dir=.rsync-partial \
        --delay-updates \
        --human-readable \
        --itemize-changes \
        --timeout=300 \
        --contimeout=60 \
        --retry-on-fail \
        "$src" "$dest" || {
        
        echo "⚠️  Transfer interrupted. Safe to resume by running the same command again."
        echo "📁 Partial files saved in: $dest/.rsync-partial/"
        echo "🔄 To resume: Just re-run this script - rsync will continue automatically"
        return 1
    }
}

# Example usage:
# rsync_enhanced "steve@server:/var/www/" "/var/www/production-mirror/web/" "web content"