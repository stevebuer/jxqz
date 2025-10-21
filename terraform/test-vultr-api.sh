#!/bin/bash

#
# test-vultr-api.sh - Test Vultr API connectivity and display cloud configuration
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$SCRIPT_DIR"

# Check for local config file and offer to source it
if [[ -f "$SCRIPT_DIR/vultr-config.sh" ]]; then
    if [[ -z "${VULTR_API_KEY:-}" ]]; then
        echo "📁 Found vultr-config.sh - sourcing API configuration..."
        source "$SCRIPT_DIR/vultr-config.sh"
    fi
fi

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
Usage: $0 [OPTIONS]

Test Vultr API connectivity and display cloud configuration.

OPTIONS:
    -k, --api-key KEY    Set Vultr API key (or use VULTR_API_KEY env var)
    -i, --init           Initialize Terraform (run first time)
    -p, --plan           Show Terraform plan without applying
    -s, --status         Get status information (default)
    -j, --json           Output in JSON format
    -h, --help           Show this help message

EXAMPLES:
    $0 --init            # First time setup
    $0 --status          # Get current status
    $0 --json            # Get status in JSON format
    
SETUP:
    1. Get your Vultr API key from: https://my.vultr.com/settings/#settingsapi
    2. Set environment variable: export VULTR_API_KEY="your-key-here"
    3. Run: $0 --init (first time only)
    4. Run: $0 --status
EOF
}

check_prerequisites() {
    log "Checking prerequisites..."
    
    # Check Terraform
    if ! command -v terraform &> /dev/null; then
        error "Terraform not found. Please install Terraform."
        echo "Install: https://learn.hashicorp.com/tutorials/terraform/install-cli"
        exit 1
    fi
    
    # Check API key
    if [[ -z "${VULTR_API_KEY:-}" ]] && [[ -z "${API_KEY:-}" ]]; then
        error "Vultr API key not found."
        echo ""
        echo "Please set your API key:"
        echo "  export VULTR_API_KEY='your-api-key-here'"
        echo ""
        echo "Get your API key from: https://my.vultr.com/settings/#settingsapi"
        exit 1
    fi
    
    success "Prerequisites check passed"
}

init_terraform() {
    log "Initializing Terraform..."
    cd "$TERRAFORM_DIR"
    
    terraform init
    success "Terraform initialized"
}

plan_terraform() {
    log "Planning Terraform configuration..."
    cd "$TERRAFORM_DIR"
    
    terraform plan -target=data.vultr_account.current \
                   -target=data.vultr_instances.existing \
                   -target=data.vultr_regions.available \
                   -target=data.vultr_plans.available
}

get_status() {
    local output_format="${1:-text}"
    
    log "Getting Vultr status information..."
    cd "$TERRAFORM_DIR"
    
    # Apply to refresh data sources (this doesn't create resources, just reads)
    log "Refreshing cloud resource data..."
    terraform apply -target=data.vultr_account.current \
                   -target=data.vultr_instances.existing \
                   -target=data.vultr_regions.available \
                   -target=data.vultr_plans.available \
                   -auto-approve
    
    if [[ "$output_format" == "json" ]]; then
        log "Generating JSON output..."
        terraform output -json
    else
        log "Vultr Cloud Configuration Summary:"
        echo ""
        
        # API Connectivity
        echo -e "${GREEN}API Connectivity:${NC}"
        terraform output -raw api_connectivity_status 2>/dev/null || echo "Connected"
        echo ""
        
        # Account Information  
        echo -e "${GREEN}Account Information:${NC}"
        terraform output account_information
        echo ""
        
        # Configuration Summary
        echo -e "${GREEN}Resource Summary:${NC}"
        terraform output configuration_summary
        echo ""
        
        # Note: Instance listing requires additional configuration
        echo -e "${GREEN}Instance Information:${NC}"
        echo "Use Vultr web console or API to view current instances"
        echo "This basic test confirms API connectivity only"
        echo ""
        
        success "Status information retrieved successfully"
    fi
}

# Parse command line arguments
INIT_TERRAFORM=false
PLAN_ONLY=false
JSON_OUTPUT=false
API_KEY=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -k|--api-key)
            API_KEY="$2"
            export VULTR_API_KEY="$API_KEY"
            shift 2
            ;;
        -i|--init)
            INIT_TERRAFORM=true
            shift
            ;;
        -p|--plan)
            PLAN_ONLY=true
            shift
            ;;
        -s|--status)
            # Default action, no need to set flag
            shift
            ;;
        -j|--json)
            JSON_OUTPUT=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Main execution
log "🌤️  Vultr API Connectivity Test"
log "Working directory: $TERRAFORM_DIR"

check_prerequisites

if [[ "$INIT_TERRAFORM" == "true" ]]; then
    init_terraform
fi

if [[ "$PLAN_ONLY" == "true" ]]; then
    plan_terraform
else
    if [[ "$JSON_OUTPUT" == "true" ]]; then
        get_status "json"
    else
        get_status "text"
    fi
fi

log "✅ Vultr API test completed successfully"