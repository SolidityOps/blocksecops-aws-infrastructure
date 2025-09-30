#!/bin/bash

# DNS Configuration Validation Script for Task 1.1
# Validates DNS configuration against best practices and security requirements
# Author: DevOps Team
# Version: 1.0

set -euo pipefail

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LOG_FILE="${SCRIPT_DIR}/dns-config-validation.log"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# DNS Security best practices
readonly MIN_TTL=300
readonly MAX_TTL=86400
readonly RECOMMENDED_TTL_MIN=3600
readonly RECOMMENDED_TTL_MAX=43200

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

    for tool in dig nslookup host whois curl; do
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
        fi
    done

    if [ ${#missing_tools[@]} -ne 0 ]; then
        error "Missing required tools: ${missing_tools[*]}"
        error "Install missing tools: ${missing_tools[*]}"
        exit 1
    fi

    success "All required dependencies are available"
}

# Validate DNS TTL values
validate_ttl_values() {
    local domain="$1"

    info "Validating TTL values for: ${domain}"

    local record_types=("A" "AAAA" "CNAME" "NS" "SOA" "MX" "TXT")

    for record_type in "${record_types[@]}"; do
        local ttl_info
        ttl_info=$(dig "$domain" "$record_type" | grep -E "^${domain//./\\.}.*${record_type}" | head -n1)

        if [ -n "$ttl_info" ]; then
            local ttl
            ttl=$(echo "$ttl_info" | awk '{print $2}')

            if [[ "$ttl" =~ ^[0-9]+$ ]]; then
                info "${record_type} record TTL: ${ttl} seconds"

                # Validate TTL against best practices
                if [ "$ttl" -lt "$MIN_TTL" ]; then
                    error "TTL too low for ${record_type} record: ${ttl}s (minimum recommended: ${MIN_TTL}s)"
                elif [ "$ttl" -gt "$MAX_TTL" ]; then
                    warn "TTL very high for ${record_type} record: ${ttl}s (maximum recommended: ${MAX_TTL}s)"
                elif [ "$ttl" -lt "$RECOMMENDED_TTL_MIN" ]; then
                    warn "TTL below recommended minimum for ${record_type} record: ${ttl}s (recommended: ${RECOMMENDED_TTL_MIN}s+)"
                elif [ "$ttl" -gt "$RECOMMENDED_TTL_MAX" ]; then
                    warn "TTL above recommended maximum for ${record_type} record: ${ttl}s (recommended: <${RECOMMENDED_TTL_MAX}s)"
                else
                    success "TTL for ${record_type} record is within recommended range: ${ttl}s"
                fi
            else
                warn "Could not parse TTL for ${record_type} record: ${ttl}"
            fi
        else
            info "No ${record_type} record found for ${domain}"
        fi
    done
}

# Check DNS security features
check_dns_security() {
    local domain="$1"

    info "Checking DNS security features for: ${domain}"

    # Check DNSSEC
    local dnssec_status
    dnssec_status=$(dig +dnssec "$domain" DS | grep -c "RRSIG\|DS" || echo "0")

    if [ "$dnssec_status" -gt 0 ]; then
        success "DNSSEC appears to be configured for ${domain}"
    else
        warn "DNSSEC not detected for ${domain} (consider enabling for production)"
    fi

    # Check CAA records
    local caa_records
    caa_records=$(dig +short "$domain" CAA)

    if [ -n "$caa_records" ]; then
        success "CAA records found for ${domain}:"
        echo "$caa_records" | while read -r caa; do
            info "  - $caa"

            # Check for common CA authorities
            if echo "$caa" | grep -q "letsencrypt.org"; then
                success "    Let's Encrypt CA authorized"
            elif echo "$caa" | grep -q "cloudflare.com"; then
                success "    Cloudflare CA authorized"
            elif echo "$caa" | grep -q "amazon.com"; then
                success "    Amazon CA authorized"
            fi
        done
    else
        warn "No CAA records found for ${domain} (consider adding for SSL security)"
        info "Example CAA record: 0 issue \"letsencrypt.org\""
    fi

    # Check SPF records
    local spf_records
    spf_records=$(dig +short "$domain" TXT | grep "v=spf1")

    if [ -n "$spf_records" ]; then
        success "SPF record found for ${domain}:"
        echo "$spf_records" | while read -r spf; do
            info "  - $spf"
        done
    else
        info "No SPF record found for ${domain} (only needed if sending email)"
    fi

    # Check DMARC records
    local dmarc_records
    dmarc_records=$(dig +short "_dmarc.${domain}" TXT | grep "v=DMARC1")

    if [ -n "$dmarc_records" ]; then
        success "DMARC record found for ${domain}:"
        echo "$dmarc_records" | while read -r dmarc; do
            info "  - $dmarc"
        done
    else
        info "No DMARC record found for ${domain} (only needed if sending email)"
    fi
}

# Validate name server configuration
validate_nameservers() {
    local domain="$1"

    info "Validating name server configuration for: ${domain}"

    # Get NS records
    local ns_records
    ns_records=$(dig +short "$domain" NS)

    if [ -z "$ns_records" ]; then
        error "No NS records found for ${domain}"
        return 1
    fi

    local ns_count
    ns_count=$(echo "$ns_records" | wc -l)

    success "Found ${ns_count} name servers for ${domain}:"

    local cloudflare_ns=0
    local other_ns=0

    echo "$ns_records" | while read -r ns; do
        info "  - $ns"

        # Check name server response
        local ns_ip
        ns_ip=$(dig +short "$ns" A | head -n1)

        if [ -n "$ns_ip" ]; then
            info "    IP: $ns_ip"

            # Test query to this name server
            local test_result
            test_result=$(dig @"$ns_ip" +short "$domain" SOA 2>/dev/null || echo "FAILED")

            if [ "$test_result" != "FAILED" ] && [ -n "$test_result" ]; then
                success "    Name server responds correctly"
            else
                error "    Name server not responding correctly"
            fi
        else
            error "    Could not resolve name server IP"
        fi

        # Check if Cloudflare NS
        if echo "$ns" | grep -q "cloudflare.com"; then
            cloudflare_ns=$((cloudflare_ns + 1))
        else
            other_ns=$((other_ns + 1))
        fi
    done

    # Validate NS count
    if [ "$ns_count" -lt 2 ]; then
        error "Insufficient name servers (${ns_count}) - minimum 2 recommended"
    elif [ "$ns_count" -gt 6 ]; then
        warn "Many name servers (${ns_count}) - may cause resolution delays"
    else
        success "Appropriate number of name servers: ${ns_count}"
    fi

    # Check for Cloudflare usage
    if [ "$cloudflare_ns" -gt 0 ]; then
        success "Using Cloudflare DNS (${cloudflare_ns} servers)"
    else
        info "Not using Cloudflare DNS"
    fi
}

# Check DNS load balancing and failover
check_dns_load_balancing() {
    local domain="$1"

    info "Checking DNS load balancing configuration for: ${domain}"

    # Check for multiple A records (round-robin DNS)
    local a_records
    a_records=$(dig +short "$domain" A)

    if [ -n "$a_records" ]; then
        local a_count
        a_count=$(echo "$a_records" | wc -l)

        if [ "$a_count" -gt 1 ]; then
            success "Multiple A records found (${a_count}) - load balancing configured:"
            echo "$a_records" | while read -r ip; do
                info "  - $ip"
            done
        else
            info "Single A record found: $(echo "$a_records" | head -n1)"
        fi
    else
        info "No A records found for ${domain}"
    fi

    # Check for GeoDNS indicators
    local geo_test_servers=("8.8.8.8" "1.1.1.1" "208.67.222.222")

    info "Testing for GeoDNS configuration..."
    local first_result=""
    local geo_detected=false

    for server in "${geo_test_servers[@]}"; do
        local result
        result=$(dig @"$server" +short "$domain" A | head -n1)

        if [ -n "$result" ]; then
            if [ -z "$first_result" ]; then
                first_result="$result"
            elif [ "$result" != "$first_result" ]; then
                geo_detected=true
            fi

            info "  DNS server $server returns: $result"
        fi
    done

    if [ "$geo_detected" = true ]; then
        success "GeoDNS configuration detected - different IPs from different locations"
    else
        info "Consistent DNS responses - no GeoDNS detected"
    fi
}

# Validate Cloudflare specific configuration
validate_cloudflare_config() {
    local domain="$1"

    info "Validating Cloudflare-specific configuration for: ${domain}"

    # Check if using Cloudflare
    local ns_records
    ns_records=$(dig +short "$domain" NS)

    if ! echo "$ns_records" | grep -q "cloudflare.com"; then
        info "Domain not using Cloudflare DNS - skipping Cloudflare-specific checks"
        return 0
    fi

    success "Domain is using Cloudflare DNS"

    # Check for Cloudflare proxy indicators
    local a_records
    a_records=$(dig +short "$domain" A)

    if [ -n "$a_records" ]; then
        echo "$a_records" | while read -r ip; do
            # Check if IP belongs to Cloudflare's proxy ranges
            # This is a simplified check - in production, you'd use the official IP ranges
            if [[ "$ip" =~ ^104\.16\. ]] || [[ "$ip" =~ ^104\.17\. ]] || [[ "$ip" =~ ^104\.18\. ]]; then
                success "IP $ip appears to be Cloudflare-proxied"
            else
                info "IP $ip - checking if Cloudflare-proxied..."
            fi
        done
    fi

    # Check for Cloudflare-specific headers via HTTP
    if command -v curl &>/dev/null; then
        local cf_headers
        cf_headers=$(curl -s -I "http://${domain}" 2>/dev/null | grep -i "cf-\|cloudflare" || echo "")

        if [ -n "$cf_headers" ]; then
            success "Cloudflare proxy headers detected:"
            echo "$cf_headers" | while read -r header; do
                info "  - $header"
            done
        else
            info "No Cloudflare proxy headers detected (domain may not be proxied)"
        fi
    fi
}

# Check DNS performance
check_dns_performance() {
    local domain="$1"

    info "Checking DNS performance for: ${domain}"

    local dns_servers=("8.8.8.8" "1.1.1.1" "208.67.222.222" "9.9.9.9")
    local total_time=0
    local query_count=0

    for dns_server in "${dns_servers[@]}"; do
        local start_time
        local end_time
        local query_time

        start_time=$(date +%s%N)
        dig @"$dns_server" +short "$domain" A >/dev/null 2>&1
        end_time=$(date +%s%N)

        query_time=$(( (end_time - start_time) / 1000000 ))  # Convert to milliseconds

        info "DNS query to $dns_server: ${query_time}ms"

        total_time=$((total_time + query_time))
        query_count=$((query_count + 1))

        # Evaluate query time
        if [ "$query_time" -lt 50 ]; then
            success "  Excellent response time"
        elif [ "$query_time" -lt 100 ]; then
            success "  Good response time"
        elif [ "$query_time" -lt 200 ]; then
            warn "  Acceptable response time"
        else
            warn "  Slow response time"
        fi
    done

    local avg_time
    avg_time=$((total_time / query_count))

    info "Average DNS query time: ${avg_time}ms"

    if [ "$avg_time" -lt 50 ]; then
        success "Excellent overall DNS performance"
    elif [ "$avg_time" -lt 100 ]; then
        success "Good overall DNS performance"
    elif [ "$avg_time" -lt 200 ]; then
        warn "Acceptable DNS performance"
    else
        error "Poor DNS performance - investigation recommended"
    fi
}

# Validate SSL/TLS certificate configuration
validate_ssl_config() {
    local domain="$1"

    info "Validating SSL/TLS certificate configuration for: ${domain}"

    # Check if HTTPS is available
    if curl -s --max-time 10 --head "https://${domain}" &>/dev/null; then
        success "HTTPS endpoint available for ${domain}"

        # Get SSL certificate information
        local ssl_info
        ssl_info=$(openssl s_client -connect "${domain}:443" -servername "$domain" </dev/null 2>/dev/null || echo "")

        if [ -n "$ssl_info" ]; then
            # Extract certificate details
            local cert_details
            cert_details=$(echo "$ssl_info" | openssl x509 -noout -text 2>/dev/null || echo "")

            if [ -n "$cert_details" ]; then
                local issuer
                local subject
                local san
                local expiry

                issuer=$(echo "$cert_details" | grep "Issuer:" | sed 's/.*Issuer: //')
                subject=$(echo "$cert_details" | grep "Subject:" | sed 's/.*Subject: //')
                san=$(echo "$cert_details" | grep -A1 "Subject Alternative Name:" | tail -n1 | sed 's/^ *//')
                expiry=$(echo "$cert_details" | grep "Not After" | sed 's/.*Not After : //')

                info "SSL Certificate details:"
                info "  Issuer: ${issuer}"
                info "  Subject: ${subject}"
                info "  SAN: ${san}"
                info "  Expires: ${expiry}"

                # Check certificate validity period
                local expiry_date
                expiry_date=$(date -d "$expiry" +%s 2>/dev/null || echo "0")
                local current_date
                current_date=$(date +%s)
                local days_until_expiry
                days_until_expiry=$(( (expiry_date - current_date) / 86400 ))

                if [ "$days_until_expiry" -gt 30 ]; then
                    success "Certificate valid for ${days_until_expiry} more days"
                elif [ "$days_until_expiry" -gt 7 ]; then
                    warn "Certificate expires in ${days_until_expiry} days"
                else
                    error "Certificate expires soon: ${days_until_expiry} days"
                fi

                # Check for Let's Encrypt
                if echo "$issuer" | grep -qi "let's encrypt"; then
                    success "Using Let's Encrypt certificate"
                fi

                # Check for wildcard certificate
                if echo "$subject$san" | grep -q "\*\."; then
                    success "Wildcard certificate detected"
                fi
            fi
        fi
    else
        info "HTTPS not available for ${domain} (expected during initial setup)"
    fi
}

# Generate comprehensive DNS configuration report
generate_config_report() {
    local domain="$1"
    local report_file="${SCRIPT_DIR}/dns-config-report.txt"

    info "Generating DNS configuration report for: ${domain}"

    cat > "$report_file" << EOF
DNS Configuration Validation Report
Domain: ${domain}
Generated: $(date)
Script Version: 1.0

=== Summary ===
EOF

    # Parse log for metrics
    local success_count
    local error_count
    local warning_count

    success_count=$(grep -c "SUCCESS" "$LOG_FILE" || echo "0")
    error_count=$(grep -c "ERROR" "$LOG_FILE" || echo "0")
    warning_count=$(grep -c "WARN" "$LOG_FILE" || echo "0")

    cat >> "$report_file" << EOF
Successful checks: ${success_count}
Errors found: ${error_count}
Warnings: ${warning_count}

=== Recommendations ===
EOF

    # Add recommendations based on findings
    if [ "$error_count" -eq 0 ] && [ "$warning_count" -eq 0 ]; then
        echo "✓ DNS configuration meets all best practices" >> "$report_file"
    else
        echo "Configuration improvements recommended:" >> "$report_file"
        if grep -q "TTL too low" "$LOG_FILE"; then
            echo "- Increase TTL values for better performance" >> "$report_file"
        fi
        if grep -q "DNSSEC not detected" "$LOG_FILE"; then
            echo "- Consider enabling DNSSEC for security" >> "$report_file"
        fi
        if grep -q "No CAA records" "$LOG_FILE"; then
            echo "- Add CAA records for SSL security" >> "$report_file"
        fi
    fi

    cat >> "$report_file" << EOF

=== Detailed Log ===
EOF

    cat "$LOG_FILE" >> "$report_file"

    success "Configuration report saved: ${report_file}"

    # Return status based on errors
    if [ "$error_count" -eq 0 ]; then
        success "DNS configuration validation completed successfully!"
        return 0
    else
        error "DNS configuration validation found ${error_count} critical issues"
        return 1
    fi
}

# Main validation function
main() {
    local domain="${1:-advancedblockchainsecurity.com}"

    # Clear previous log
    > "$LOG_FILE"

    info "Starting DNS configuration validation for: ${domain}"
    echo

    check_dependencies

    # Run all validation checks
    validate_ttl_values "$domain"
    check_dns_security "$domain"
    validate_nameservers "$domain"
    check_dns_load_balancing "$domain"
    validate_cloudflare_config "$domain"
    check_dns_performance "$domain"
    validate_ssl_config "$domain"

    # Generate comprehensive report
    generate_config_report "$domain"
}

# Usage function
usage() {
    cat << EOF
Usage: $0 [DOMAIN]

DNS Configuration Validation Script for Task 1.1

ARGUMENTS:
    DOMAIN                      Domain to validate (default: advancedblockchainsecurity.com)

VALIDATION CHECKS:
    - TTL value validation against best practices
    - DNS security features (DNSSEC, CAA, SPF, DMARC)
    - Name server configuration and redundancy
    - Load balancing and failover setup
    - Cloudflare-specific configuration
    - DNS performance metrics
    - SSL/TLS certificate configuration

EXAMPLES:
    $0                          # Validate default domain
    $0 example.com             # Validate custom domain

OUTPUT FILES:
    - dns-config-validation.log     # Detailed log
    - dns-config-report.txt         # Summary report with recommendations

BEST PRACTICES VALIDATED:
    - TTL: ${MIN_TTL}-${MAX_TTL} seconds (recommended: ${RECOMMENDED_TTL_MIN}-${RECOMMENDED_TTL_MAX})
    - Minimum 2 name servers
    - DNSSEC enabled
    - CAA records for SSL security
    - Appropriate DNS performance (<200ms)
EOF
}

# Handle help flag
if [[ "${1:-}" == "-h" ]] || [[ "${1:-}" == "--help" ]]; then
    usage
    exit 0
fi

# Run main function
main "$@"