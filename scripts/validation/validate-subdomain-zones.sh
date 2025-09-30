#!/bin/bash

# Subdomain Zone Validation Script for Task 1.1
# Validates subdomain zone configuration and SSL certificate preparation
# Author: DevOps Team
# Version: 1.0

set -euo pipefail

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LOG_FILE="${SCRIPT_DIR}/subdomain-validation.log"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Logging functions
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${timestamp} [${level}] ${message}" | tee -a "${LOG_FILE}"
}

info() { log "INFO" "${BLUE}$*${NC}"; }
warn() { log "WARN" "${YELLOW}$*${NC}"; }
error() { log "ERROR" "${RED}$*${NC}"; }
success() { log "SUCCESS" "${GREEN}$*${NC}"; }

# Check required tools
check_dependencies() {
    info "Checking required dependencies..."
    local missing_tools=()

    for tool in dig nslookup openssl curl; do
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
        fi
    done

    if [ ${#missing_tools[@]} -ne 0 ]; then
        error "Missing required tools: ${missing_tools[*]}"
        exit 1
    fi

    success "All required dependencies are available"
}

# Validate subdomain DNS configuration
validate_subdomain_dns() {
    local subdomain="$1"
    local environment="$2"

    info "Validating DNS configuration for: ${subdomain} (${environment})"

    # Check A records
    local a_records
    a_records=$(dig +short "$subdomain" A)

    if [ -n "$a_records" ]; then
        success "A records found for ${subdomain}:"
        echo "$a_records" | while read -r ip; do
            info "  - $ip"

            # Validate IP format
            if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
                success "    Valid IPv4 address format"
            else
                warn "    Invalid IPv4 address format: $ip"
            fi
        done
    else
        warn "No A records found for ${subdomain}"
    fi

    # Check AAAA records (IPv6)
    local aaaa_records
    aaaa_records=$(dig +short "$subdomain" AAAA)

    if [ -n "$aaaa_records" ]; then
        success "AAAA records found for ${subdomain}:"
        echo "$aaaa_records" | while read -r ipv6; do
            info "  - $ipv6"
        done
    else
        info "No AAAA records found for ${subdomain} (IPv6 not configured)"
    fi

    # Check CNAME records
    local cname_records
    cname_records=$(dig +short "$subdomain" CNAME)

    if [ -n "$cname_records" ]; then
        success "CNAME records found for ${subdomain}:"
        echo "$cname_records" | while read -r cname; do
            info "  - $cname"
        done
    else
        info "No CNAME records found for ${subdomain}"
    fi

    # Check TXT records (important for SSL validation)
    local txt_records
    txt_records=$(dig +short "$subdomain" TXT)

    if [ -n "$txt_records" ]; then
        info "TXT records found for ${subdomain}:"
        echo "$txt_records" | while read -r txt; do
            info "  - $txt"

            # Check for common validation patterns
            if echo "$txt" | grep -q "_acme-challenge"; then
                success "    ACME challenge record detected"
            elif echo "$txt" | grep -q "v=spf1"; then
                info "    SPF record detected"
            elif echo "$txt" | grep -q "google-site-verification"; then
                info "    Google site verification detected"
            fi
        done
    else
        info "No TXT records found for ${subdomain}"
    fi
}

# Check wildcard subdomain support
check_wildcard_support() {
    local subdomain="$1"
    local environment="$2"

    info "Checking wildcard support for: ${subdomain}"

    # Test common wildcard patterns
    local wildcard_tests=(
        "api.${subdomain}"
        "www.${subdomain}"
        "test.${subdomain}"
        "*.${subdomain}"
    )

    for wildcard_test in "${wildcard_tests[@]}"; do
        local result
        result=$(dig +short "$wildcard_test" A)

        if [ -n "$result" ]; then
            success "Wildcard test passed: ${wildcard_test} -> ${result}"
        else
            info "No wildcard response for: ${wildcard_test}"
        fi
    done

    # Check for explicit wildcard A record
    local wildcard_record
    wildcard_record=$(dig +short "*.${subdomain}" A)

    if [ -n "$wildcard_record" ]; then
        success "Explicit wildcard A record found for *.${subdomain}: ${wildcard_record}"
    else
        info "No explicit wildcard A record found for *.${subdomain}"
    fi
}

# Validate SSL certificate configuration readiness
validate_ssl_readiness() {
    local subdomain="$1"
    local environment="$2"

    info "Validating SSL certificate readiness for: ${subdomain}"

    # Check if subdomain is reachable via HTTPS
    if curl -s --max-time 10 --head "https://${subdomain}" &>/dev/null; then
        success "HTTPS endpoint is reachable for ${subdomain}"

        # Get certificate information
        local cert_info
        cert_info=$(openssl s_client -connect "${subdomain}:443" -servername "$subdomain" </dev/null 2>/dev/null | openssl x509 -noout -text 2>/dev/null || echo "")

        if [ -n "$cert_info" ]; then
            # Extract certificate details
            local issuer
            local subject
            local expiry

            issuer=$(echo "$cert_info" | grep "Issuer:" | head -n1 | sed 's/.*Issuer: //')
            subject=$(echo "$cert_info" | grep "Subject:" | head -n1 | sed 's/.*Subject: //')
            expiry=$(echo "$cert_info" | grep "Not After" | head -n1 | sed 's/.*Not After : //')

            info "SSL Certificate details:"
            info "  Issuer: ${issuer}"
            info "  Subject: ${subject}"
            info "  Expires: ${expiry}"

            # Check if it's a Let's Encrypt certificate
            if echo "$issuer" | grep -i "let's encrypt" &>/dev/null; then
                success "Let's Encrypt certificate detected"
            elif echo "$issuer" | grep -i "cloudflare" &>/dev/null; then
                success "Cloudflare certificate detected"
            else
                info "Certificate from: ${issuer}"
            fi
        else
            warn "Could not retrieve certificate information"
        fi
    else
        info "HTTPS endpoint not yet available for ${subdomain} (expected during initial setup)"
    fi

    # Check for DNS-01 challenge preparation
    local acme_challenge
    acme_challenge=$(dig +short "_acme-challenge.${subdomain}" TXT)

    if [ -n "$acme_challenge" ]; then
        success "ACME challenge TXT record found for ${subdomain}"
        info "Challenge record: ${acme_challenge}"
    else
        info "No ACME challenge record found (normal before certificate issuance)"
    fi
}

# Check subdomain zone delegation
check_zone_delegation() {
    local subdomain="$1"
    local parent_domain="$2"

    info "Checking zone delegation for: ${subdomain}"

    # Check if subdomain has its own NS records
    local subdomain_ns
    subdomain_ns=$(dig +short "$subdomain" NS)

    if [ -n "$subdomain_ns" ]; then
        success "Subdomain has dedicated NS records:"
        echo "$subdomain_ns" | while read -r ns; do
            info "  - $ns"
        done
    else
        info "Subdomain uses parent domain NS records (common configuration)"

        # Check parent domain NS records
        local parent_ns
        parent_ns=$(dig +short "$parent_domain" NS)

        if [ -n "$parent_ns" ]; then
            info "Parent domain NS records:"
            echo "$parent_ns" | while read -r ns; do
                info "  - $ns"
            done
        fi
    fi

    # Check SOA record
    local soa_record
    soa_record=$(dig +short "$subdomain" SOA)

    if [ -n "$soa_record" ]; then
        success "SOA record found for ${subdomain}: ${soa_record}"
    else
        info "No SOA record found for ${subdomain} (inherits from parent)"
    fi
}

# Validate service discovery preparation
validate_service_discovery() {
    local subdomain="$1"
    local environment="$2"

    info "Validating service discovery preparation for: ${subdomain}"

    # Common service subdomains to check
    local service_subdomains=(
        "api.${subdomain}"
        "dashboard.${subdomain}"
        "argocd.${subdomain}"
        "grafana.${subdomain}"
        "prometheus.${subdomain}"
        "vault.${subdomain}"
    )

    for service_subdomain in "${service_subdomains[@]}"; do
        local result
        result=$(dig +short "$service_subdomain" A)

        if [ -n "$result" ]; then
            success "Service subdomain configured: ${service_subdomain} -> ${result}"
        else
            info "Service subdomain not yet configured: ${service_subdomain}"
        fi
    done

    # Check for SRV records (service discovery)
    local srv_records
    srv_records=$(dig +short "$subdomain" SRV)

    if [ -n "$srv_records" ]; then
        success "SRV records found for service discovery:"
        echo "$srv_records" | while read -r srv; do
            info "  - $srv"
        done
    else
        info "No SRV records found (not commonly used with Kubernetes)"
    fi
}

# Check load balancer preparation
check_load_balancer_readiness() {
    local subdomain="$1"
    local environment="$2"

    info "Checking load balancer readiness for: ${subdomain}"

    # Check for AWS Load Balancer target
    local a_records
    a_records=$(dig +short "$subdomain" A)

    if [ -n "$a_records" ]; then
        echo "$a_records" | while read -r ip; do
            # Check if IP belongs to AWS (rough check)
            if curl -s --max-time 5 "https://ip-ranges.amazonaws.com/ip-ranges.json" | \
               grep -q "$ip" 2>/dev/null; then
                success "IP $ip appears to be AWS-hosted (potential ALB target)"
            else
                info "IP $ip - checking connectivity..."

                # Basic connectivity check
                if ping -c 1 -W 3 "$ip" &>/dev/null; then
                    success "IP $ip is reachable"
                else
                    warn "IP $ip is not reachable"
                fi
            fi
        done
    fi

    # Check for CNAME pointing to load balancer
    local cname_records
    cname_records=$(dig +short "$subdomain" CNAME)

    if [ -n "$cname_records" ]; then
        echo "$cname_records" | while read -r cname; do
            if echo "$cname" | grep -q "\.elb\.amazonaws\.com"; then
                success "CNAME points to AWS ELB: $cname"
            elif echo "$cname" | grep -q "\.cloudflare\."; then
                success "CNAME points to Cloudflare: $cname"
            else
                info "CNAME target: $cname"
            fi
        done
    fi
}

# Generate subdomain validation report
generate_subdomain_report() {
    local subdomains=("$@")
    local report_file="${SCRIPT_DIR}/subdomain-validation-report.txt"

    info "Generating subdomain validation report..."

    cat > "$report_file" << EOF
Subdomain Zone Validation Report
Generated: $(date)
Subdomains tested: ${subdomains[*]}

=== Validation Summary ===
EOF

    # Parse log for success/error counts
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

=== Detailed Results ===
EOF

    cat "$LOG_FILE" >> "$report_file"

    success "Subdomain validation report saved: ${report_file}"

    if [ "$error_count" -eq 0 ]; then
        success "All subdomain validations completed successfully!"
    else
        warn "Found ${error_count} errors during validation"
    fi
}

# Main validation function
main() {
    local domain="${1:-advancedblockchainsecurity.com}"
    local staging_subdomain="${2:-staging.${domain}}"
    local production_subdomain="${3:-app.${domain}}"

    # Clear previous log
    > "$LOG_FILE"

    info "Starting subdomain zone validation for Task 1.1"
    info "Domain: ${domain}"
    info "Staging subdomain: ${staging_subdomain}"
    info "Production subdomain: ${production_subdomain}"
    echo

    check_dependencies

    # Validate staging subdomain
    info "=== STAGING SUBDOMAIN VALIDATION ==="
    validate_subdomain_dns "$staging_subdomain" "staging"
    check_wildcard_support "$staging_subdomain" "staging"
    validate_ssl_readiness "$staging_subdomain" "staging"
    check_zone_delegation "$staging_subdomain" "$domain"
    validate_service_discovery "$staging_subdomain" "staging"
    check_load_balancer_readiness "$staging_subdomain" "staging"
    echo

    # Validate production subdomain
    info "=== PRODUCTION SUBDOMAIN VALIDATION ==="
    validate_subdomain_dns "$production_subdomain" "production"
    check_wildcard_support "$production_subdomain" "production"
    validate_ssl_readiness "$production_subdomain" "production"
    check_zone_delegation "$production_subdomain" "$domain"
    validate_service_discovery "$production_subdomain" "production"
    check_load_balancer_readiness "$production_subdomain" "production"
    echo

    # Generate report
    generate_subdomain_report "$staging_subdomain" "$production_subdomain"
}

# Usage function
usage() {
    cat << EOF
Usage: $0 [DOMAIN] [STAGING_SUBDOMAIN] [PRODUCTION_SUBDOMAIN]

Subdomain Zone Validation Script for Task 1.1

ARGUMENTS:
    DOMAIN                      Main domain (default: advancedblockchainsecurity.com)
    STAGING_SUBDOMAIN          Staging subdomain (default: staging.DOMAIN)
    PRODUCTION_SUBDOMAIN       Production subdomain (default: app.DOMAIN)

EXAMPLES:
    $0                                                          # Use defaults
    $0 example.com                                             # Custom domain
    $0 example.com dev.example.com prod.example.com           # Custom subdomains

VALIDATION CHECKS:
    - DNS record configuration (A, AAAA, CNAME, TXT, NS, SOA)
    - Wildcard subdomain support
    - SSL certificate readiness
    - Zone delegation configuration
    - Service discovery preparation
    - Load balancer readiness

OUTPUT:
    - Console output with color-coded results
    - Log file: subdomain-validation.log
    - Report file: subdomain-validation-report.txt
EOF
}

# Handle help flag
if [[ "${1:-}" == "-h" ]] || [[ "${1:-}" == "--help" ]]; then
    usage
    exit 0
fi

# Run main function
main "$@"