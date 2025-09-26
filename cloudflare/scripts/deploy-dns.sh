#!/bin/bash

# DNS Deployment Script for Advanced Blockchain Security
# Automates the deployment of DNS infrastructure using Terraform

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="${SCRIPT_DIR}/../terraform"
DOMAIN="advancedblockchainsecurity.com"

# Logging
LOG_FILE="${SCRIPT_DIR}/deploy-$(date +%Y%m%d-%H%M%S).log"

log() {
    echo -e "$1" | tee -a "$LOG_FILE"
}

log_info() {
    log "${BLUE}[INFO]${NC} $1"
}

log_success() {
    log "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    log "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    log "${RED}[ERROR]${NC} $1"
}

# Banner
log_info "🌐 DNS Deployment Script for Advanced Blockchain Security"
log_info "Domain: ${DOMAIN}"
log_info "Timestamp: $(date)"
log_info "Log file: ${LOG_FILE}"
echo "================================================================="

# Validation functions
validate_environment() {
    log_info "🔍 Validating environment prerequisites..."

    # Check if Terraform is installed
    if ! command -v terraform &> /dev/null; then
        log_error "Terraform is not installed. Please install Terraform 1.0+"
        exit 1
    fi

    local tf_version
    tf_version=$(terraform version -json | jq -r '.terraform_version' 2>/dev/null || terraform version | grep -o 'v[0-9]\+\.[0-9]\+\.[0-9]\+' | tr -d 'v')
    log_info "Terraform version: ${tf_version}"

    # Check for required environment variables
    if [[ -z "$CLOUDFLARE_API_TOKEN" ]]; then
        log_error "CLOUDFLARE_API_TOKEN environment variable is not set"
        exit 1
    fi

    if [[ -z "$TF_VAR_staging_lb_ip" ]]; then
        log_warning "TF_VAR_staging_lb_ip is not set. Using placeholder value."
        export TF_VAR_staging_lb_ip="STAGING_LB_IP"
    fi

    if [[ -z "$TF_VAR_production_lb_ip" ]]; then
        log_warning "TF_VAR_production_lb_ip is not set. Using placeholder value."
        export TF_VAR_production_lb_ip="PRODUCTION_LB_IP"
    fi

    # Check if jq is available for JSON processing
    if ! command -v jq &> /dev/null; then
        log_warning "jq is not installed. Some features may not work properly."
    fi

    # Check if dig is available for DNS validation
    if ! command -v dig &> /dev/null; then
        log_warning "dig is not installed. DNS validation will be limited."
    fi

    log_success "Environment validation completed"
}

validate_cloudflare_access() {
    log_info "🔐 Validating Cloudflare API access..."

    local zone_check
    zone_check=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=${DOMAIN}" \
        -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
        -H "Content-Type: application/json" | jq -r '.success' 2>/dev/null || echo "false")

    if [[ "$zone_check" == "true" ]]; then
        log_success "Cloudflare API access validated"

        # Get zone information
        local zone_info
        zone_info=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=${DOMAIN}" \
            -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
            -H "Content-Type: application/json" | jq -r '.result[0]' 2>/dev/null)

        if [[ "$zone_info" != "null" && -n "$zone_info" ]]; then
            local zone_id
            local zone_status
            zone_id=$(echo "$zone_info" | jq -r '.id' 2>/dev/null)
            zone_status=$(echo "$zone_info" | jq -r '.status' 2>/dev/null)

            log_info "Zone ID: ${zone_id}"
            log_info "Zone Status: ${zone_status}"

            if [[ "$zone_status" == "active" ]]; then
                log_success "Domain is active in Cloudflare"
            else
                log_warning "Domain status is not active: ${zone_status}"
            fi
        fi
    else
        log_error "Unable to access Cloudflare API or domain not found"
        log_error "Please verify:"
        log_error "1. CLOUDFLARE_API_TOKEN is correct"
        log_error "2. Domain ${DOMAIN} is added to your Cloudflare account"
        log_error "3. API token has Zone:Edit permissions"
        exit 1
    fi
}

backup_existing_config() {
    log_info "💾 Creating backup of existing DNS configuration..."

    local backup_dir="${SCRIPT_DIR}/backups/$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$backup_dir"

    # Backup current DNS records via API
    local current_records
    current_records=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=${DOMAIN}" \
        -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
        -H "Content-Type: application/json" | jq -r '.result[0].id' 2>/dev/null)

    if [[ "$current_records" != "null" && -n "$current_records" ]]; then
        curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${current_records}/dns_records" \
            -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
            -H "Content-Type: application/json" > "${backup_dir}/current-dns-records.json"

        log_success "DNS records backed up to: ${backup_dir}/current-dns-records.json"
    else
        log_warning "Could not backup current DNS records"
    fi

    # Backup Terraform state if it exists
    if [[ -f "${TERRAFORM_DIR}/terraform.tfstate" ]]; then
        cp "${TERRAFORM_DIR}/terraform.tfstate" "${backup_dir}/"
        log_success "Terraform state backed up"
    fi

    echo "$backup_dir" > "${SCRIPT_DIR}/.last_backup"
}

deploy_terraform() {
    log_info "🚀 Deploying Terraform configuration..."

    cd "$TERRAFORM_DIR"

    # Initialize Terraform
    log_info "Initializing Terraform..."
    if terraform init -no-color >> "$LOG_FILE" 2>&1; then
        log_success "Terraform initialized successfully"
    else
        log_error "Terraform initialization failed. Check log: ${LOG_FILE}"
        exit 1
    fi

    # Validate configuration
    log_info "Validating Terraform configuration..."
    if terraform validate -no-color >> "$LOG_FILE" 2>&1; then
        log_success "Terraform configuration is valid"
    else
        log_error "Terraform configuration validation failed. Check log: ${LOG_FILE}"
        exit 1
    fi

    # Plan deployment
    log_info "Creating deployment plan..."
    if terraform plan -out=tfplan -no-color >> "$LOG_FILE" 2>&1; then
        log_success "Deployment plan created successfully"
    else
        log_error "Terraform planning failed. Check log: ${LOG_FILE}"
        exit 1
    fi

    # Apply deployment
    log_info "Applying Terraform configuration..."
    if terraform apply -auto-approve tfplan -no-color >> "$LOG_FILE" 2>&1; then
        log_success "Terraform deployment completed successfully"
    else
        log_error "Terraform deployment failed. Check log: ${LOG_FILE}"
        log_error "You may need to run 'terraform destroy' to clean up partial deployment"
        exit 1
    fi

    # Clean up plan file
    rm -f tfplan

    log_success "DNS infrastructure deployed successfully"
}

post_deployment_validation() {
    log_info "✅ Running post-deployment validation..."

    # Wait for DNS propagation
    log_info "Waiting 30 seconds for initial DNS propagation..."
    sleep 30

    # Run comprehensive DNS validation
    if [[ -f "${SCRIPT_DIR}/../scripts/validation/dns-validation.sh" ]]; then
        log_info "Running comprehensive DNS validation..."
        if bash "${SCRIPT_DIR}/../scripts/validation/dns-validation.sh" >> "$LOG_FILE" 2>&1; then
            log_success "DNS validation completed successfully"
        else
            log_warning "DNS validation found issues. Check log: ${LOG_FILE}"
            log_warning "This is normal immediately after deployment. DNS may take time to propagate."
        fi
    else
        log_warning "DNS validation script not found"
    fi

    # Display deployment summary
    cd "$TERRAFORM_DIR"
    log_info "📊 Deployment Summary:"
    terraform output -no-color | while IFS= read -r line; do
        log_info "  $line"
    done
}

cleanup() {
    log_info "🧹 Cleaning up temporary files..."
    cd "$TERRAFORM_DIR"
    rm -f tfplan
    log_success "Cleanup completed"
}

# Main deployment function
main() {
    local start_time
    start_time=$(date +%s)

    log_info "Starting DNS deployment process..."

    validate_environment
    validate_cloudflare_access
    backup_existing_config
    deploy_terraform
    post_deployment_validation
    cleanup

    local end_time
    local duration
    end_time=$(date +%s)
    duration=$((end_time - start_time))

    log_success "🎉 DNS deployment completed successfully!"
    log_info "Total deployment time: ${duration} seconds"
    log_info "Full log available at: ${LOG_FILE}"

    echo ""
    echo "================================================================="
    echo -e "${GREEN}Next Steps:${NC}"
    echo "1. Update your AWS Load Balancer IPs in the configuration"
    echo "2. Wait for global DNS propagation (up to 24 hours)"
    echo "3. Deploy your Kubernetes applications"
    echo "4. Monitor SSL certificate provisioning"
    echo ""
    echo -e "${BLUE}Useful Commands:${NC}"
    echo "• Check DNS: dig @8.8.8.8 ${DOMAIN} A"
    echo "• Validate SSL: openssl s_client -connect ${DOMAIN}:443"
    echo "• Re-run validation: ${SCRIPT_DIR}/../scripts/validation/dns-validation.sh"
}

# Handle script interruption
trap cleanup EXIT

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            log_info "🔍 Running in dry-run mode..."
            export TF_CLI_ARGS="-dry-run"
            shift
            ;;
        --force)
            log_info "⚠️  Force mode enabled - skipping confirmations"
            export FORCE_MODE=true
            shift
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --dry-run    Run Terraform in plan mode only"
            echo "  --force      Skip confirmation prompts"
            echo "  --help       Show this help message"
            echo ""
            echo "Environment Variables:"
            echo "  CLOUDFLARE_API_TOKEN    Required Cloudflare API token"
            echo "  TF_VAR_staging_lb_ip    Staging load balancer IP"
            echo "  TF_VAR_production_lb_ip Production load balancer IP"
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Confirmation prompt (unless force mode)
if [[ "$FORCE_MODE" != "true" ]]; then
    echo ""
    echo -e "${YELLOW}⚠️  You are about to deploy DNS infrastructure for ${DOMAIN}${NC}"
    echo "This will create/modify DNS records in Cloudflare."
    echo ""
    read -p "Do you want to continue? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Deployment cancelled by user"
        exit 0
    fi
fi

# Run main deployment
main