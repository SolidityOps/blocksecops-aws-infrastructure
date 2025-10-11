# DNS Validation Scripts for Task 1.1

This directory contains comprehensive DNS validation scripts for Task 1.1 domain registration and DNS infrastructure setup.

## Overview

These scripts validate the DNS infrastructure established in Task 1.1, ensuring proper domain registration, DNS zone configuration, subdomain setup, and SSL certificate preparation for the BlockSecOps Platform.

## Scripts

### 1. `validate-dns-infrastructure.sh`
**Main comprehensive DNS validation script**

```bash
./validate-dns-infrastructure.sh [OPTIONS]
```

**Features:**
- Domain registration validation
- Cloudflare DNS management verification
- Subdomain zone validation
- DNS propagation checking
- SSL certificate preparation validation
- TTL configuration analysis

**Options:**
- `-d, --domain DOMAIN` - Domain to validate (default: advancedblockchainsecurity.com)
- `-s, --staging SUBDOMAIN` - Staging subdomain (default: staging.DOMAIN)
- `-p, --production SUBDOMAIN` - Production subdomain (default: app.DOMAIN)
- `-h, --help` - Show help message

**Example:**
```bash
# Validate default domain
./validate-dns-infrastructure.sh

# Validate custom domain
./validate-dns-infrastructure.sh -d example.com

# Validate with custom subdomains
./validate-dns-infrastructure.sh -d example.com -s dev.example.com -p prod.example.com
```

### 2. `check-dns-propagation.sh`
**Global DNS propagation checker**

```bash
./check-dns-propagation.sh DOMAIN [MODE] [OPTIONS]
```

**Modes:**
- `check` - Basic propagation check (default)
- `detailed` - Check all record types
- `monitor` - Continuous monitoring

**Features:**
- Tests 12+ global DNS servers
- Geographic distribution checking
- Consistency analysis
- Performance metrics
- Online tool integration

**Examples:**
```bash
# Basic propagation check
./check-dns-propagation.sh example.com

# Detailed check with all record types
./check-dns-propagation.sh example.com detailed

# Monitor propagation changes every 5 minutes for 2 hours
./check-dns-propagation.sh example.com monitor 300 24
```

### 3. `validate-subdomain-zones.sh`
**Subdomain-specific validation**

```bash
./validate-subdomain-zones.sh [DOMAIN] [STAGING_SUBDOMAIN] [PRODUCTION_SUBDOMAIN]
```

**Features:**
- DNS record configuration validation
- Wildcard subdomain support checking
- SSL certificate readiness
- Zone delegation analysis
- Service discovery preparation
- Load balancer readiness

**Example:**
```bash
# Validate with defaults
./validate-subdomain-zones.sh

# Validate custom configuration
./validate-subdomain-zones.sh example.com dev.example.com prod.example.com
```

### 4. `validate-dns-config.sh`
**DNS configuration best practices validation**

```bash
./validate-dns-config.sh [DOMAIN]
```

**Features:**
- TTL value validation
- DNS security features (DNSSEC, CAA, SPF, DMARC)
- Name server configuration
- Load balancing setup
- Cloudflare-specific checks
- Performance analysis
- SSL/TLS certificate validation

**Example:**
```bash
# Validate DNS configuration
./validate-dns-config.sh example.com
```

## Quick Start

### 1. Make Scripts Executable
```bash
chmod +x scripts/validation/*.sh
```

### 2. Run Full Infrastructure Validation
```bash
# Navigate to validation directory
cd scripts/validation

# Run comprehensive validation
./validate-dns-infrastructure.sh

# Check propagation status
./check-dns-propagation.sh advancedblockchainsecurity.com
```

### 3. Monitor Setup Progress
```bash
# Monitor DNS propagation during setup
./check-dns-propagation.sh advancedblockchainsecurity.com monitor 300 48
```

## Dependencies

All scripts require the following tools:
- `dig` - DNS lookup tool
- `nslookup` - DNS lookup tool
- `curl` - HTTP client for online checks
- `openssl` - SSL certificate analysis
- `whois` - Domain registration info (optional)

### Install Dependencies

**Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get install dnsutils curl openssl whois
```

**macOS:**
```bash
# Most tools are pre-installed
brew install whois  # if needed
```

**CentOS/RHEL:**
```bash
sudo yum install bind-utils curl openssl whois
```

## Output Files

Each script generates log files and reports:

### Log Files
- `dns-validation.log` - Main validation log
- `dns-propagation.log` - Propagation check log
- `subdomain-validation.log` - Subdomain validation log
- `dns-config-validation.log` - Configuration validation log

### Report Files
- `dns-validation-report.txt` - Comprehensive infrastructure report
- `dns-propagation-report-[domain].txt` - Propagation analysis report
- `subdomain-validation-report.txt` - Subdomain setup report
- `dns-config-report.txt` - Configuration best practices report

## Task 1.1 Validation Checklist

Use these scripts to validate Task 1.1 completion:

### ✅ Domain Registration
```bash
./validate-dns-infrastructure.sh -d advancedblockchainsecurity.com
```
Validates:
- [ ] Domain registered and responding
- [ ] SOA and NS records configured
- [ ] Cloudflare DNS management active

### ✅ DNS Zone Setup
```bash
./validate-dns-config.sh advancedblockchainsecurity.com
```
Validates:
- [ ] Name server configuration
- [ ] TTL values appropriate
- [ ] DNS security features

### ✅ Subdomain Configuration
```bash
./validate-subdomain-zones.sh
```
Validates:
- [ ] staging.advancedblockchainsecurity.com zone
- [ ] app.advancedblockchainsecurity.com zone
- [ ] Wildcard subdomain support
- [ ] SSL certificate preparation

### ✅ Global Propagation
```bash
./check-dns-propagation.sh advancedblockchainsecurity.com detailed
```
Validates:
- [ ] Global DNS propagation complete
- [ ] Consistent responses across regions
- [ ] Performance within acceptable limits

## Integration with Future Tasks

These scripts prepare for future infrastructure tasks:

### Task 1.6 (Kubernetes Infrastructure)
- Validates DNS zones for ArgoCD and service endpoints
- Checks wildcard support for dynamic service routing
- Verifies SSL certificate preparation for cert-manager

### Load Balancer Integration
- Validates DNS structure for AWS Load Balancer targets
- Checks TTL configuration for load balancer updates
- Verifies subdomain structure for service routing

### SSL Certificate Management
- Validates domain ownership for Let's Encrypt
- Checks CAA records for certificate authority authorization
- Verifies DNS-01 challenge preparation

## Troubleshooting

### Common Issues

**DNS Propagation Delays:**
```bash
# Monitor propagation status
./check-dns-propagation.sh example.com monitor
```

**Cloudflare Configuration:**
```bash
# Verify Cloudflare settings
./validate-dns-config.sh example.com | grep -i cloudflare
```

**Subdomain Issues:**
```bash
# Debug subdomain configuration
./validate-subdomain-zones.sh example.com staging.example.com app.example.com
```

### Debug Mode

Enable verbose logging by setting:
```bash
export DEBUG=1
./validate-dns-infrastructure.sh
```

## Security Considerations

### Best Practices Validated
- TTL values (300-86400 seconds recommended)
- DNSSEC configuration
- CAA records for SSL security
- Name server redundancy (minimum 2)
- DNS performance (<200ms response time)

### Security Features Checked
- DNSSEC validation
- CAA record configuration
- SPF/DMARC records (if applicable)
- SSL certificate configuration
- Cloudflare security features

## Support

For issues with these scripts:
1. Check the generated log files for detailed error messages
2. Verify all dependencies are installed
3. Ensure proper network connectivity for DNS queries
4. Review the validation reports for specific recommendations

## Version History

- **v1.0** - Initial release for Task 1.1
  - Comprehensive DNS infrastructure validation
  - Global propagation checking
  - Subdomain zone validation
  - Configuration best practices validation