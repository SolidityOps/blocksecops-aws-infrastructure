#!/bin/bash

# DNS Propagation Checker Script for Task 1.1
# Checks DNS propagation across multiple global DNS servers and geographic locations
# Author: DevOps Team
# Version: 1.0

set -euo pipefail

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LOG_FILE="${SCRIPT_DIR}/dns-propagation.log"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Global DNS servers with labels
declare -A DNS_SERVERS=(
    ["Google Primary"]="8.8.8.8"
    ["Google Secondary"]="8.8.4.4"
    ["Cloudflare Primary"]="1.1.1.1"
    ["Cloudflare Secondary"]="1.0.0.1"
    ["OpenDNS Primary"]="208.67.222.222"
    ["OpenDNS Secondary"]="208.67.220.220"
    ["Quad9 Primary"]="9.9.9.9"
    ["Quad9 Secondary"]="149.112.112.112"
    ["Level3"]="4.2.2.2"
    ["Comodo"]="8.26.56.26"
    ["CleanBrowsing"]="185.228.168.9"
    ["AdGuard"]="94.140.14.14"
)

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

    for tool in dig nslookup curl; do
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

# Query specific DNS server
query_dns_server() {
    local server="$1"
    local domain="$2"
    local record_type="${3:-A}"
    local timeout="${4:-5}"

    local result
    result=$(timeout "$timeout" dig @"$server" +short "$domain" "$record_type" 2>/dev/null || echo "TIMEOUT")

    if [ "$result" = "TIMEOUT" ]; then
        echo "TIMEOUT"
    elif [ -z "$result" ]; then
        echo "NO_RECORD"
    else
        echo "$result"
    fi
}

# Check propagation for a single domain
check_domain_propagation() {
    local domain="$1"
    local record_type="${2:-A}"

    info "Checking DNS propagation for: ${domain} (${record_type} record)"
    echo

    local results=()
    local all_responses=()
    local successful_queries=0
    local total_queries=0

    # Query all DNS servers
    for server_name in "${!DNS_SERVERS[@]}"; do
        local server_ip="${DNS_SERVERS[$server_name]}"
        local result

        total_queries=$((total_queries + 1))
        result=$(query_dns_server "$server_ip" "$domain" "$record_type")

        # Store result for analysis
        results+=("$server_name:$result")
        all_responses+=("$result")

        # Format output
        local status_color="$RED"
        local status_symbol="✗"

        if [ "$result" != "TIMEOUT" ] && [ "$result" != "NO_RECORD" ]; then
            status_color="$GREEN"
            status_symbol="✓"
            successful_queries=$((successful_queries + 1))
        elif [ "$result" = "NO_RECORD" ]; then
            status_color="$YELLOW"
            status_symbol="○"
        fi

        printf "  ${status_color}${status_symbol}${NC} %-20s %-15s %s\n" "$server_name" "$server_ip" "$result"
    done

    echo

    # Analyze results
    analyze_propagation_results "$domain" "$record_type" "${all_responses[@]}"

    # Calculate success rate
    local success_rate
    success_rate=$(( (successful_queries * 100) / total_queries ))

    if [ "$success_rate" -eq 100 ]; then
        success "DNS propagation: ${success_rate}% (${successful_queries}/${total_queries}) - Fully propagated"
    elif [ "$success_rate" -ge 80 ]; then
        warn "DNS propagation: ${success_rate}% (${successful_queries}/${total_queries}) - Mostly propagated"
    elif [ "$success_rate" -ge 50 ]; then
        warn "DNS propagation: ${success_rate}% (${successful_queries}/${total_queries}) - Partially propagated"
    else
        error "DNS propagation: ${success_rate}% (${successful_queries}/${total_queries}) - Poor propagation"
    fi

    return $((100 - success_rate))
}

# Analyze propagation results
analyze_propagation_results() {
    local domain="$1"
    local record_type="$2"
    shift 2
    local responses=("$@")

    # Count unique responses
    local unique_responses
    unique_responses=$(printf '%s\n' "${responses[@]}" | sort | uniq)
    local unique_count
    unique_count=$(echo "$unique_responses" | wc -l)

    info "Analysis for ${domain} (${record_type}):"

    if [ "$unique_count" -eq 1 ]; then
        local single_response
        single_response=$(echo "$unique_responses" | head -n1)
        if [ "$single_response" = "TIMEOUT" ]; then
            error "  All queries timed out - DNS servers may be unreachable"
        elif [ "$single_response" = "NO_RECORD" ]; then
            warn "  Consistent response: No ${record_type} record found"
        else
            success "  Consistent response across all servers: $single_response"
        fi
    else
        warn "  Inconsistent responses detected (${unique_count} different responses):"
        while IFS= read -r response; do
            local count
            count=$(printf '%s\n' "${responses[@]}" | grep -c "^$response$" || echo "0")
            info "    $response (${count} servers)"
        done <<< "$unique_responses"
    fi
}

# Check DNS propagation using online tools
check_online_propagation() {
    local domain="$1"

    info "Checking online DNS propagation tools for: ${domain}"

    # Check using whatsmydns.net API (if available)
    if command -v curl &> /dev/null; then
        info "Attempting to check propagation via online tools..."

        # Simple curl check to see if domain resolves from different locations
        local online_check_result
        online_check_result=$(curl -s --max-time 10 "https://dns.google/resolve?name=${domain}&type=A" 2>/dev/null || echo "FAILED")

        if [ "$online_check_result" != "FAILED" ] && echo "$online_check_result" | grep -q "Answer"; then
            success "Domain resolves via Google DNS API"
        else
            warn "Could not verify via Google DNS API (this is normal if domain is not yet configured)"
        fi
    fi
}

# Check specific record types
check_record_types() {
    local domain="$1"
    local record_types=("A" "AAAA" "CNAME" "NS" "SOA" "MX" "TXT")

    info "Checking different record types for: ${domain}"
    echo

    for record_type in "${record_types[@]}"; do
        # Quick check using one DNS server to see if record type exists
        local test_result
        test_result=$(query_dns_server "8.8.8.8" "$domain" "$record_type")

        if [ "$test_result" != "TIMEOUT" ] && [ "$test_result" != "NO_RECORD" ]; then
            info "Found ${record_type} record, checking propagation..."
            check_domain_propagation "$domain" "$record_type"
            echo
        else
            info "No ${record_type} record found for ${domain}"
        fi
    done
}

# Generate propagation report
generate_propagation_report() {
    local domain="$1"
    local report_file="${SCRIPT_DIR}/dns-propagation-report-${domain//\./-}.txt"

    info "Generating DNS propagation report for: ${domain}"

    cat > "$report_file" << EOF
DNS Propagation Report
Domain: ${domain}
Generated: $(date)
Checked from: $(hostname) ($(curl -s ifconfig.me 2>/dev/null || echo "Unknown IP"))

=== DNS Servers Tested ===
EOF

    for server_name in "${!DNS_SERVERS[@]}"; do
        echo "${server_name}: ${DNS_SERVERS[$server_name]}" >> "$report_file"
    done

    cat >> "$report_file" << EOF

=== Propagation Test Results ===
EOF

    # Add log contents
    cat "$LOG_FILE" >> "$report_file"

    success "Propagation report saved: ${report_file}"
}

# Monitor propagation changes
monitor_propagation() {
    local domain="$1"
    local interval="${2:-300}"  # 5 minutes default
    local max_iterations="${3:-24}"  # 2 hours default

    info "Starting DNS propagation monitoring for: ${domain}"
    info "Check interval: ${interval} seconds"
    info "Maximum iterations: ${max_iterations}"

    local iteration=0
    local last_results_hash=""

    while [ "$iteration" -lt "$max_iterations" ]; do
        iteration=$((iteration + 1))
        info "Monitoring iteration ${iteration}/${max_iterations} at $(date)"

        # Capture current results
        local current_results=""
        for server_name in "${!DNS_SERVERS[@]}"; do
            local server_ip="${DNS_SERVERS[$server_name]}"
            local result
            result=$(query_dns_server "$server_ip" "$domain" "A")
            current_results="${current_results}${server_name}:${result}\n"
        done

        # Hash results to detect changes
        local current_hash
        current_hash=$(echo -e "$current_results" | md5sum | cut -d' ' -f1)

        if [ -n "$last_results_hash" ] && [ "$current_hash" != "$last_results_hash" ]; then
            warn "DNS propagation change detected at iteration ${iteration}!"
            check_domain_propagation "$domain" "A"
        elif [ "$iteration" -eq 1 ]; then
            check_domain_propagation "$domain" "A"
        else
            info "No changes detected (hash: ${current_hash:0:8}...)"
        fi

        last_results_hash="$current_hash"

        if [ "$iteration" -lt "$max_iterations" ]; then
            info "Waiting ${interval} seconds until next check..."
            sleep "$interval"
        fi
    done

    info "DNS propagation monitoring completed"
}

# Main function
main() {
    local domain="${1:-}"
    local mode="${2:-check}"

    if [ -z "$domain" ]; then
        error "Domain parameter is required"
        usage
        exit 1
    fi

    # Clear previous log
    > "$LOG_FILE"

    info "Starting DNS propagation check for: ${domain}"
    info "Mode: ${mode}"
    echo

    check_dependencies

    case "$mode" in
        "check")
            check_domain_propagation "$domain"
            check_online_propagation "$domain"
            generate_propagation_report "$domain"
            ;;
        "detailed")
            check_record_types "$domain"
            check_online_propagation "$domain"
            generate_propagation_report "$domain"
            ;;
        "monitor")
            local interval="${3:-300}"
            local max_iterations="${4:-24}"
            monitor_propagation "$domain" "$interval" "$max_iterations"
            generate_propagation_report "$domain"
            ;;
        *)
            error "Unknown mode: $mode"
            usage
            exit 1
            ;;
    esac
}

# Usage function
usage() {
    cat << EOF
Usage: $0 DOMAIN [MODE] [OPTIONS]

DNS Propagation Checker Script for Task 1.1

ARGUMENTS:
    DOMAIN                      Domain to check (required)

MODES:
    check                       Basic propagation check (default)
    detailed                    Check all record types
    monitor                     Continuous monitoring

OPTIONS (for monitor mode):
    INTERVAL                    Check interval in seconds (default: 300)
    MAX_ITERATIONS             Maximum iterations (default: 24)

EXAMPLES:
    $0 example.com                           # Basic check
    $0 example.com detailed                  # Detailed check
    $0 example.com monitor                   # Monitor with defaults
    $0 example.com monitor 60 48             # Monitor every 60s for 48 iterations

DNS SERVERS TESTED:
    - Google DNS (8.8.8.8, 8.8.4.4)
    - Cloudflare DNS (1.1.1.1, 1.0.0.1)
    - OpenDNS (208.67.222.222, 208.67.220.220)
    - Quad9 (9.9.9.9, 149.112.112.112)
    - Level3, Comodo, CleanBrowsing, AdGuard
EOF
}

# Parse arguments and run
if [ $# -eq 0 ]; then
    usage
    exit 1
fi

main "$@"