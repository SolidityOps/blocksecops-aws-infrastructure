# Cloudflare DNS Configuration for Advanced Blockchain Security

This directory contains the complete DNS infrastructure configuration for the domain `advancedblockchainsecurity.com` using Cloudflare as the DNS provider.

## Directory Structure

```
cloudflare/
├── terraform/                     # Terraform infrastructure configuration
│   ├── main.tf                   # Main Cloudflare resources
│   ├── variables.tf              # Input variables
│   └── outputs.tf                # Output values
├── dns-records/                   # DNS record configurations
│   ├── production-records.yaml   # Production environment DNS records
│   └── staging-records.yaml      # Staging environment DNS records
├── subdomain-configs/             # Subdomain specific configurations
│   ├── production.json           # Production subdomain settings
│   └── staging.json              # Staging subdomain settings
└── scripts/                      # Management and validation scripts
    └── deploy-dns.sh             # DNS deployment automation
```

## Prerequisites

1. **Domain Registration**: `advancedblockchainsecurity.com` must be registered and active
2. **Cloudflare Account**: Domain added to Cloudflare with nameservers properly configured
3. **Terraform**: Version 1.0+ installed locally
4. **Cloudflare API Token**: With Zone:Edit permissions for the domain
5. **AWS Infrastructure**: Load Balancer IPs from completed Tasks 1.2-1.6 deployment
6. **AWS CLI**: Configured for retrieving Load Balancer information (optional)

## Environment Variables

Set the following environment variables before deployment:

```bash
export CLOUDFLARE_API_TOKEN="your_cloudflare_api_token"
export TF_VAR_staging_lb_ip="STAGING_ALB_IP"
export TF_VAR_production_lb_ip="PRODUCTION_ALB_IP"
```

## DNS Records Overview

### Production Environment

| Subdomain | Type | Target | Description |
|-----------|------|--------|-------------|
| @ | A | PRODUCTION_LB_IP | Root domain |
| www | CNAME | advancedblockchainsecurity.com | WWW redirect |
| api | A | PRODUCTION_LB_IP | API endpoints |
| dashboard | A | PRODUCTION_LB_IP | Dashboard interface |
| vault | A | PRODUCTION_LB_IP | Vault UI (no proxy) |
| argocd | A | PRODUCTION_LB_IP | ArgoCD interface |
| monitoring | A | PRODUCTION_LB_IP | Grafana/Prometheus |

### Staging Environment

| Subdomain | Type | Target | Description |
|-----------|------|--------|-------------|
| staging | A | STAGING_LB_IP | Staging environment |
| api-staging | A | STAGING_LB_IP | Staging API |
| dashboard-staging | A | STAGING_LB_IP | Staging dashboard |
| vault-staging | A | STAGING_LB_IP | Staging Vault UI |
| argocd-staging | A | STAGING_LB_IP | Staging ArgoCD |
| monitoring-staging | A | STAGING_LB_IP | Staging monitoring |

## Security Configuration

### SSL/TLS Settings
- **Encryption Mode**: Full (Strict)
- **Min TLS Version**: 1.2
- **HSTS**: Enabled with 1-year max-age
- **Always Use HTTPS**: Enabled

### WAF and Protection
- **Web Application Firewall**: Enabled
- **DDoS Protection**: Enabled
- **Rate Limiting**: 500 req/min, 5000 req/hour (production)
- **Geo-blocking**: China, Russia, North Korea (production only)

### Security Headers
- `X-Frame-Options: SAMEORIGIN`
- `X-Content-Type-Options: nosniff`
- `Referrer-Policy: strict-origin-when-cross-origin`
- `Permissions-Policy: camera=(), microphone=(), geolocation=()`

## Deployment Instructions

### Automated Deployment (Recommended)

**⚠️ Important:** You must have AWS Load Balancer IPs before deploying DNS records.

```bash
cd cloudflare/

# Set required environment variables
export CLOUDFLARE_API_TOKEN="your_cloudflare_api_token"
export TF_VAR_staging_lb_ip="your-staging-alb-ip"
export TF_VAR_production_lb_ip="your-production-alb-ip"

# Deploy DNS infrastructure using automated script
./scripts/deploy-dns.sh
```

The automated script includes:
- Environment validation
- Cloudflare API access verification
- Configuration backup
- Terraform deployment
- Post-deployment validation
- Comprehensive logging

### Manual Deployment (Advanced Users)

```bash
cd cloudflare/terraform/

# Set environment variables
export CLOUDFLARE_API_TOKEN="your_cloudflare_api_token"
export TF_VAR_staging_lb_ip="your-staging-alb-ip"
export TF_VAR_production_lb_ip="your-production-alb-ip"

# Initialize and deploy
terraform init
terraform plan
terraform apply

# Verify deployment
terraform output
```

### Deployment Options

The automated script supports several options:

```bash
# Dry run (plan only)
./scripts/deploy-dns.sh --dry-run

# Force deployment (skip confirmations)
./scripts/deploy-dns.sh --force

# Help and usage
./scripts/deploy-dns.sh --help
```

## Load Balancer IP Configuration

**Critical Requirement:** DNS deployment requires actual AWS Application Load Balancer IPs.

### Getting Load Balancer IPs

After deploying AWS infrastructure (Tasks 1.2-1.6), get the Load Balancer IPs:

```bash
# Get ALB DNS names from AWS
aws elbv2 describe-load-balancers --query 'LoadBalancers[?contains(LoadBalancerName, `staging`)].DNSName' --output text
aws elbv2 describe-load-balancers --query 'LoadBalancers[?contains(LoadBalancerName, `production`)].DNSName' --output text

# Resolve to IP addresses
nslookup staging-alb-dns-name.us-west-2.elb.amazonaws.com
nslookup production-alb-dns-name.us-west-2.elb.amazonaws.com
```

### Setting Environment Variables

```bash
# Use the resolved IP addresses
export TF_VAR_staging_lb_ip="198.51.100.1"  # Replace with actual staging ALB IP
export TF_VAR_production_lb_ip="203.0.113.1"  # Replace with actual production ALB IP
```

**Note:** The Terraform configuration automatically uses these environment variables - no manual file editing required.

## SSL Certificate Management

SSL certificates are automatically managed through:
- **Production**: Let's Encrypt with cert-manager
- **Staging**: Let's Encrypt staging environment
- **Auto-renewal**: Enabled for all certificates

## Monitoring and Validation

### DNS Propagation Check
```bash
# Check global DNS propagation
dig @8.8.8.8 advancedblockchainsecurity.com A
dig @1.1.1.1 api.advancedblockchainsecurity.com A
```

### SSL Certificate Validation
```bash
# Check SSL certificate
openssl s_client -servername advancedblockchainsecurity.com -connect advancedblockchainsecurity.com:443
```

### Performance Testing
```bash
# Test response times
curl -w "@curl-format.txt" -o /dev/null -s "https://advancedblockchainsecurity.com"
```

## Troubleshooting

### Common Issues

1. **DNS Not Propagating**
   - Check nameservers: `dig NS advancedblockchainsecurity.com`
   - Wait up to 24 hours for global propagation
   - Verify Cloudflare proxy status

2. **SSL Certificate Issues**
   - Ensure domain validation is complete
   - Check cert-manager logs in Kubernetes
   - Verify Let's Encrypt rate limits

3. **Load Balancer Not Responding**
   - Verify AWS ALB is provisioned and healthy
   - Check security group configurations
   - Validate target group health

### Support Commands

```bash
# Check Cloudflare zone status
curl -X GET "https://api.cloudflare.com/client/v4/zones" \
     -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN"

# Validate specific DNS record
nslookup api.advancedblockchainsecurity.com 1.1.1.1

# Test HTTP to HTTPS redirect
curl -I http://advancedblockchainsecurity.com
```

## Maintenance

### Regular Tasks
1. **Monthly**: Review DNS analytics and performance metrics
2. **Quarterly**: Update security configurations and review access logs
3. **Annually**: Rotate Cloudflare API tokens

### Updates
- DNS record changes: Update via Terraform
- Security policy updates: Modify JSON configurations
- SSL certificate renewal: Automated via cert-manager

## Integration with Kubernetes

The DNS configuration integrates with:
- **AWS Load Balancer Controller**: For ALB provisioning
- **cert-manager**: For SSL certificate automation
- **ExternalDNS**: For dynamic DNS record management (optional)

Ensure the following annotations are used in Kubernetes Ingress resources:
```yaml
annotations:
  kubernetes.io/ingress.class: alb
  alb.ingress.kubernetes.io/scheme: internet-facing
  cert-manager.io/cluster-issuer: letsencrypt-prod
```