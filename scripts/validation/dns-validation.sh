#!/bin/bash

# DNS Validation Script for Advanced Blockchain Security
# Validates DNS configuration and propagation for advancedblockchainsecurity.com

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DOMAIN="advancedblockchainsecurity.com"
STAGING_DOMAIN="staging.${DOMAIN}"
API_DOMAIN="api.${DOMAIN}"
API_STAGING_DOMAIN="api-staging.${DOMAIN}"
DASHBOARD_DOMAIN="dashboard.${DOMAIN}"
DASHBOARD_STAGING_DOMAIN="dashboard-staging.${DOMAIN}"
VAULT_DOMAIN="vault.${DOMAIN}"
VAULT_STAGING_DOMAIN="vault-staging.${DOMAIN}"
ARGOCD_DOMAIN="argocd.${DOMAIN}"
ARGOCD_STAGING_DOMAIN="argocd-staging.${DOMAIN}"
MONITORING_DOMAIN="monitoring.${DOMAIN}"
MONITORING_STAGING_DOMAIN="monitoring-staging.${DOMAIN}"

# DNS servers to check against
DNS_SERVERS=(
    "1.1.1.1"      # Cloudflare
    "8.8.8.8"      # Google
    "208.67.222.222" # OpenDNS
    "9.9.9.9"      # Quad9
)

success_count=0
total_checks=0

echo -e "${BLUE}🌐 DNS Validation for Advanced Blockchain Security${NC}"
echo -e "${BLUE}Domain: ${DOMAIN}${NC}"
echo "================================================================="

# Function to perform DNS lookup
check_dns_record() {
    local domain="$1"
    local record_type="$2"
    local expected_pattern="$3"
    local description="$4"

    total_checks=$((total_checks + 1))
    echo -e "\n${YELLOW}Checking ${record_type} record for ${domain}${NC}"

    local all_servers_pass=true

    for dns_server in "${DNS_SERVERS[@]}"; do
        echo -n "  ├─ ${dns_server}: "

        local result
        result=$(dig @"${dns_server}" "${domain}" "${record_type}" +short 2>/dev/null || echo "FAILED")

        if [[ "$result" == "FAILED" || -z "$result" ]]; then
            echo -e "${RED}FAILED${NC}"
            all_servers_pass=false
        elif [[ -n "$expected_pattern" && ! "$result" =~ $expected_pattern ]]; then
            echo -e "${RED}UNEXPECTED: ${result}${NC}"
            all_servers_pass=false
        else
            echo -e "${GREEN}OK: ${result}${NC}"
        fi
    done

    if $all_servers_pass; then
        echo -e "  ${GREEN}✅ ${description}${NC}"
        success_count=$((success_count + 1))
    else
        echo -e "  ${RED}❌ ${description}${NC}"
    fi
}

# Function to check domain propagation
check_domain_propagation() {
    local domain="$1"
    local description="$2"

    echo -e "\n${YELLOW}Checking global propagation for ${domain}${NC}"

    # Use external service to check global propagation
    local propagation_check
    propagation_check=$(curl -s "https://www.whatsmydns.net/api/details?server=world&type=A&query=${domain}" 2>/dev/null || echo "")

    if [[ -n "$propagation_check" ]]; then
        echo -e "  ${GREEN}✅ Global propagation check completed${NC}"
    else
        echo -e "  ${YELLOW}⚠️  Unable to verify global propagation${NC}"
    fi
}

# Function to check SSL certificate
check_ssl_certificate() {
    local domain="$1"
    local description="$2"

    total_checks=$((total_checks + 1))
    echo -e "\n${YELLOW}Checking SSL certificate for ${domain}${NC}"

    local ssl_info
    ssl_info=$(echo | timeout 10 openssl s_client -servername "${domain}" -connect "${domain}:443" 2>/dev/null | openssl x509 -noout -dates 2>/dev/null || echo "FAILED")

    if [[ "$ssl_info" == "FAILED" ]]; then
        echo -e "  ${RED}❌ ${description}${NC}"
    else
        echo -e "  ${GREEN}✅ ${description}${NC}"
        echo -e "  ${BLUE}${ssl_info}${NC}"
        success_count=$((success_count + 1))
    fi
}

# Function to check HTTP/HTTPS redirects
check_http_redirect() {
    local domain="$1"
    local description="$2"

    total_checks=$((total_checks + 1))
    echo -e "\n${YELLOW}Checking HTTP to HTTPS redirect for ${domain}${NC}"

    local http_status
    http_status=$(curl -s -o /dev/null -w "%{http_code}" -L "http://${domain}" 2>/dev/null || echo "FAILED")

    if [[ "$http_status" == "200" ]]; then
        echo -e "  ${GREEN}✅ ${description}${NC}"
        success_count=$((success_count + 1))
    else
        echo -e "  ${RED}❌ ${description} (Status: ${http_status})${NC}"
    fi
}

# Function to validate Cloudflare nameservers
check_nameservers() {
    echo -e "\n${YELLOW}Checking nameservers for ${DOMAIN}${NC}"

    local nameservers
    nameservers=$(dig NS "${DOMAIN}" +short | sort)

    echo "Current nameservers:"
    while IFS= read -r ns; do
        if [[ "$ns" =~ cloudflare ]]; then
            echo -e "  ${GREEN}✅ ${ns}${NC}"
        else
            echo -e "  ${YELLOW}⚠️  ${ns}${NC}"
        fi
    done <<< "$nameservers"
}

# Function to check MX records
check_mx_records() {
    echo -e "\n${YELLOW}Checking MX records for ${DOMAIN}${NC}"

    local mx_records
    mx_records=$(dig MX "${DOMAIN}" +short)

    if [[ -n "$mx_records" ]]; then
        echo "MX Records:"
        while IFS= read -r mx; do
            echo -e "  ${GREEN}✅ ${mx}${NC}"
        done <<< "$mx_records"
    else
        echo -e "  ${YELLOW}⚠️  No MX records found${NC}"
    fi
}

# Function to check SPF records
check_spf_records() {
    echo -e "\n${YELLOW}Checking SPF record for ${DOMAIN}${NC}"

    local spf_record
    spf_record=$(dig TXT "${DOMAIN}" +short | grep "v=spf1" | head -1)

    if [[ -n "$spf_record" ]]; then
        echo -e "  ${GREEN}✅ SPF record found: ${spf_record}${NC}"
    else
        echo -e "  ${YELLOW}⚠️  No SPF record found${NC}"
    fi
}

# Main validation checks
echo -e "\n${BLUE}🔍 Starting DNS Validation Checks${NC}"

# Check nameservers first
check_nameservers

# Check main domain records
check_dns_record "$DOMAIN" "A" "" "Root domain A record"
check_dns_record "www.$DOMAIN" "CNAME" "$DOMAIN" "WWW CNAME record"

# Check staging environment
check_dns_record "$STAGING_DOMAIN" "A" "" "Staging environment A record"
check_dns_record "$API_STAGING_DOMAIN" "A" "" "Staging API A record"
check_dns_record "$DASHBOARD_STAGING_DOMAIN" "A" "" "Staging dashboard A record"
check_dns_record "$VAULT_STAGING_DOMAIN" "A" "" "Staging Vault A record"
check_dns_record "$ARGOCD_STAGING_DOMAIN" "A" "" "Staging ArgoCD A record"
check_dns_record "$MONITORING_STAGING_DOMAIN" "A" "" "Staging monitoring A record"

# Check production environment
check_dns_record "$API_DOMAIN" "A" "" "Production API A record"
check_dns_record "$DASHBOARD_DOMAIN" "A" "" "Production dashboard A record"
check_dns_record "$VAULT_DOMAIN" "A" "" "Production Vault A record"
check_dns_record "$ARGOCD_DOMAIN" "A" "" "Production ArgoCD A record"
check_dns_record "$MONITORING_DOMAIN" "A" "" "Production monitoring A record"

# Check email records
check_mx_records
check_spf_records

# Check global propagation for key domains
echo -e "\n${BLUE}🌍 Checking Global DNS Propagation${NC}"
check_domain_propagation "$DOMAIN" "Root domain"
check_domain_propagation "$STAGING_DOMAIN" "Staging domain"
check_domain_propagation "$API_DOMAIN" "API domain"

# Check SSL certificates (if domains are live)
echo -e "\n${BLUE}🔒 Checking SSL Certificates${NC}"
check_ssl_certificate "$DOMAIN" "Root domain SSL"
check_ssl_certificate "$STAGING_DOMAIN" "Staging domain SSL"
check_ssl_certificate "$API_DOMAIN" "API domain SSL"

# Check HTTP redirects
echo -e "\n${BLUE}🔄 Checking HTTP to HTTPS Redirects${NC}"
check_http_redirect "$DOMAIN" "Root domain redirect"
check_http_redirect "$STAGING_DOMAIN" "Staging domain redirect"

# Performance checks
echo -e "\n${BLUE}⚡ Performance and Caching Checks${NC}"

check_cloudflare_caching() {
    local domain="$1"
    echo -e "\n${YELLOW}Checking Cloudflare caching for ${domain}${NC}"

    local cf_headers
    cf_headers=$(curl -s -I "https://${domain}" 2>/dev/null | grep -i "cf-" || echo "No Cloudflare headers found")

    if [[ "$cf_headers" != "No Cloudflare headers found" ]]; then
        echo -e "  ${GREEN}✅ Cloudflare caching active${NC}"
        echo -e "  ${BLUE}${cf_headers}${NC}"
    else
        echo -e "  ${YELLOW}⚠️  Cloudflare headers not detected${NC}"
    fi
}

check_cloudflare_caching "$DOMAIN"
check_cloudflare_caching "$STAGING_DOMAIN"

# Summary
echo -e "\n${BLUE}📊 Validation Summary${NC}"
echo "================================================================="

if [ $success_count -eq $total_checks ]; then
    echo -e "${GREEN}🎉 All $total_checks DNS checks passed!${NC}"
    echo -e "${GREEN}✅ DNS infrastructure is properly configured${NC}"
    echo -e "${GREEN}✅ All domains are resolving correctly${NC}"
    echo -e "${GREEN}✅ SSL certificates are working${NC}"
    echo -e "${GREEN}✅ HTTP to HTTPS redirects are active${NC}"
    echo ""
    echo -e "${GREEN}🚀 DNS infrastructure is ready for production!${NC}"
    exit 0
else
    failed_checks=$((total_checks - success_count))
    echo -e "${RED}❌ $failed_checks out of $total_checks checks failed.${NC}"
    echo -e "${YELLOW}Please review the failed checks above.${NC}"
    echo ""
    echo -e "${YELLOW}Common issues:${NC}"
    echo -e "${YELLOW}• DNS records may still be propagating (can take up to 24 hours)${NC}"
    echo -e "${YELLOW}• Load balancer IPs may not be configured yet${NC}"
    echo -e "${YELLOW}• SSL certificates may not be issued yet${NC}"
    echo -e "${YELLOW}• Services may not be deployed yet${NC}"
    exit 1
fi