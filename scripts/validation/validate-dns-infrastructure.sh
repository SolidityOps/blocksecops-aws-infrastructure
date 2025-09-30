#!/bin/bash

# DNS Infrastructure Validation Script for Task 1.1
# Validates domain registration, DNS zones, and subdomain configuration
# Author: DevOps Team
# Version: 1.0

set -euo pipefail

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LOG_FILE="${SCRIPT_DIR}/dns-validation.log"
readonly DOMAIN="${DOMAIN:-advancedblockchainsecurity.com}"
readonly STAGING_SUBDOMAIN="${STAGING_SUBDOMAIN:-staging.${DOMAIN}}"
readonly PRODUCTION_SUBDOMAIN="${PRODUCTION_SUBDOMAIN:-app.${DOMAIN}}"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Logging function
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${timestamp} [${level}] ${message}" | tee -a "${LOG_FILE}"
}

info() { log "INFO" "$@"; }
warn() { log "WARN" "${YELLOW}$*${NC}"; }
error() { log "ERROR" "${RED}$*${NC}"; }
success() { log "SUCCESS" "${GREEN}$*${NC}"; }

# Check required tools
check_dependencies() {
    info "Checking required dependencies..."
    local missing_tools=()

    for tool in dig nslookup curl jq; do
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
        fi
    done

    if [ ${#missing_tools[@]} -ne 0 ]; then
        error "Missing required tools: ${missing_tools[*]}"
        error "Please install missing tools and run again"
        exit 1
    fi

    success "All required dependencies are available"
}

# Validate domain registration and basic DNS response
validate_domain_registration() {
    info "Validating domain registration for: ${DOMAIN}"

    # Check if domain resolves to any record
    if dig +short "${DOMAIN}" A | grep -q .; then
        success "Domain ${DOMAIN} is registered and has DNS records"
    else
        warn "Domain ${DOMAIN} does not have A records (this might be expected during initial setup)"
    fi

    # Check for SOA record (indicates DNS zone exists)
    local soa_record
    soa_record=$(dig +short "${DOMAIN}" SOA | head -n1)

    if [ -n "$soa_record" ]; then
        success "DNS zone exists for ${DOMAIN}"
        info "SOA record: ${soa_record}"
    else
        error "No SOA record found for ${DOMAIN} - DNS zone may not be configured"
        return 1
    fi

    # Check for NS records
    local ns_records
    ns_records=$(dig +short "${DOMAIN}" NS)

    if [ -n "$ns_records" ]; then
        success "Name servers configured for ${DOMAIN}:"
        echo "$ns_records" | while read -r ns; do
            info "  - $ns"
        done
    else
        error "No NS records found for ${DOMAIN}"
        return 1
    fi
}

# Validate Cloudflare DNS management
validate_cloudflare_dns() {
    info "Validating Cloudflare DNS management..."

    # Check if domain uses Cloudflare name servers
    local ns_records
    ns_records=$(dig +short "${DOMAIN}" NS)

    if echo "$ns_records" | grep -q "cloudflare.com"; then
        success "Domain is using Cloudflare name servers"
        echo "$ns_records" | grep "cloudflare.com" | while read -r ns; do
            info "  - $ns"
        done
    else
        warn "Domain may not be using Cloudflare name servers"
        info "Current name servers:"
        echo "$ns_records" | while read -r ns; do
            info "  - $ns"
        done
    fi
}

# Validate subdomain zones
validate_subdomain_zones() {
    info "Validating subdomain zones..."

    local subdomains=("$STAGING_SUBDOMAIN" "$PRODUCTION_SUBDOMAIN")

    for subdomain in "${subdomains[@]}"; do
        info "Checking subdomain: ${subdomain}"

        # Check if subdomain has any DNS records
        local has_records=false

        # Check for A records
        if dig +short "${subdomain}" A | grep -q .; then
            success "Subdomain ${subdomain} has A records"
            has_records=true
        fi

        # Check for CNAME records
        if dig +short "${subdomain}" CNAME | grep -q .; then
            success "Subdomain ${subdomain} has CNAME records"
            has_records=true
        fi

        # Check for wildcard support
        local wildcard_subdomain="test.${subdomain}"
        if dig +short "${wildcard_subdomain}" A | grep -q .; then
            success "Wildcard DNS appears to be configured for ${subdomain}"
        fi

        if [ "$has_records" = false ]; then
            warn "Subdomain ${subdomain} has no DNS records (this might be expected during initial setup)"
        fi
    done
}

# Check DNS propagation globally
check_dns_propagation() {
    info "Checking DNS propagation globally..."

    # List of public DNS servers to check
    local dns_servers=(
        "8.8.8.8"      # Google
        "1.1.1.1"      # Cloudflare
        "208.67.222.222" # OpenDNS
        "9.9.9.9"      # Quad9
    )

    local domains_to_check=("$DOMAIN" "$STAGING_SUBDOMAIN" "$PRODUCTION_SUBDOMAIN")

    for domain in "${domains_to_check[@]}"; do
        info "Checking propagation for: ${domain}"
        local consistent=true
        local first_result=""

        for dns_server in "${dns_servers[@]}"; do
            local result
            result=$(dig @"$dns_server" +short "$domain" A 2>/dev/null || echo "TIMEOUT")

            if [ -z "$first_result" ]; then
                first_result="$result"
            elif [ "$result" != "$first_result" ]; then
                consistent=false
            fi

            info "  ${dns_server}: ${result:-"No A record"}"
        done

        if [ "$consistent" = true ] && [ -n "$first_result" ] && [ "$first_result" != "TIMEOUT" ]; then
            success "DNS propagation is consistent for ${domain}"
        else
            warn "DNS propagation may be incomplete for ${domain}"
        fi
    done
}

# Validate SSL certificate preparation
validate_ssl_preparation() {
    info "Validating SSL certificate preparation..."

    # Check for TXT records that might be used for domain validation
    local domains_to_check=("$DOMAIN" "$STAGING_SUBDOMAIN" "$PRODUCTION_SUBDOMAIN")

    for domain in "${domains_to_check[@]}"; do
        local txt_records
        txt_records=$(dig +short "${domain}" TXT)

        if [ -n "$txt_records" ]; then
            info "TXT records found for ${domain}:"
            echo "$txt_records" | while read -r txt; do
                info "  - $txt"
            done
        else
            info "No TXT records found for ${domain} (normal for initial setup)"
        fi
    done
}

# Validate DNS TTL values
validate_dns_ttls() {
    info "Validating DNS TTL values..."

    local domains_to_check=("$DOMAIN" "$STAGING_SUBDOMAIN" "$PRODUCTION_SUBDOMAIN")

    for domain in "${domains_to_check[@]}"; do
        # Get TTL for A records
        local ttl_info
        ttl_info=$(dig "$domain" A | grep -E "^${domain//./\\.}" | head -n1)

        if [ -n "$ttl_info" ]; then
            local ttl
            ttl=$(echo "$ttl_info" | awk '{print $2}')
            info "TTL for ${domain}: ${ttl} seconds"

            if [ "$ttl" -lt 300 ]; then
                warn "TTL for ${domain} is very low (${ttl}s) - consider increasing for production"
            elif [ "$ttl" -gt 86400 ]; then
                warn "TTL for ${domain} is very high (${ttl}s) - consider decreasing for faster updates"
            else
                success "TTL for ${domain} is appropriate (${ttl}s)"
            fi
        else
            info "No A records found for ${domain} to check TTL"
        fi
    done
}

# Generate validation report
generate_report() {
    info "Generating DNS validation report..."

    local report_file="${SCRIPT_DIR}/dns-validation-report.txt"
    cat > "$report_file" << EOF
DNS Infrastructure Validation Report
Generated: $(date)
Domain: ${DOMAIN}
Staging Subdomain: ${STAGING_SUBDOMAIN}
Production Subdomain: ${PRODUCTION_SUBDOMAIN}

=== Validation Results ===
EOF

    # Parse log file for success/error counts
    local success_count
    local error_count
    local warning_count

    success_count=$(grep -c "SUCCESS" "$LOG_FILE" || echo "0")
    error_count=$(grep -c "ERROR" "$LOG_FILE" || echo "0")
    warning_count=$(grep -c "WARN" "$LOG_FILE" || echo "0")

    cat >> "$report_file" << EOF
Successful validations: ${success_count}
Errors found: ${error_count}
Warnings: ${warning_count}

=== Detailed Log ===
EOF

    cat "$LOG_FILE" >> "$report_file"

    success "Validation report generated: ${report_file}"

    if [ "$error_count" -eq 0 ]; then
        success "DNS infrastructure validation completed successfully!"
        return 0
    else
        error "DNS infrastructure validation found ${error_count} errors"
        return 1
    fi
}

# Main validation function
main() {
    info "Starting DNS infrastructure validation for Task 1.1"
    info "Domain: ${DOMAIN}"
    info "Staging Subdomain: ${STAGING_SUBDOMAIN}"
    info "Production Subdomain: ${PRODUCTION_SUBDOMAIN}"
    echo

    # Clear previous log
    > "$LOG_FILE"

    # Run all validation checks
    check_dependencies
    validate_domain_registration
    validate_cloudflare_dns
    validate_subdomain_zones
    check_dns_propagation
    validate_ssl_preparation
    validate_dns_ttls

    # Generate final report
    generate_report
}

# Script usage
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

DNS Infrastructure Validation Script for Task 1.1

OPTIONS:
    -d, --domain DOMAIN           Domain to validate (default: advancedblockchainsecurity.com)
    -s, --staging SUBDOMAIN       Staging subdomain (default: staging.DOMAIN)
    -p, --production SUBDOMAIN    Production subdomain (default: app.DOMAIN)
    -h, --help                   Show this help message

EXAMPLES:
    $0                           # Use default domain
    $0 -d example.com            # Validate custom domain
    $0 -d example.com -s dev.example.com -p prod.example.com

ENVIRONMENT VARIABLES:
    DOMAIN                       Override default domain
    STAGING_SUBDOMAIN           Override staging subdomain
    PRODUCTION_SUBDOMAIN        Override production subdomain
EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--domain)
            DOMAIN="$2"
            shift 2
            ;;
        -s|--staging)
            STAGING_SUBDOMAIN="$2"
            shift 2
            ;;
        -p|--production)
            PRODUCTION_SUBDOMAIN="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Run main function
main "$@"