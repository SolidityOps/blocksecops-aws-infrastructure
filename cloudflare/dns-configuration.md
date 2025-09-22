# Cloudflare Enterprise DNS Configuration for advancedblockchainsecurity.com

Since your domain `advancedblockchainsecurity.com` is managed with Cloudflare Enterprise, you get advanced security, performance, and reliability features including WAF, DDoS protection, SSL/TLS management, and global CDN. This eliminates the need for AWS WAF, CloudFront, Route53 health checks, and certificate management.

## Required DNS Records

Once your AWS infrastructure is deployed and you have the Application Load Balancer (ALB) DNS name, configure these DNS records in Cloudflare:

### Development Environment (dev)

```
Type: CNAME
Name: dev
Target: <AWS_ALB_DNS_NAME>
Proxy Status: Proxied (Orange Cloud)
TTL: Auto

Type: CNAME
Name: api.dev
Target: <AWS_ALB_DNS_NAME>
Proxy Status: Proxied (Orange Cloud)
TTL: Auto

Type: CNAME
Name: app.dev
Target: <AWS_ALB_DNS_NAME>
Proxy Status: Proxied (Orange Cloud)
TTL: Auto

Type: CNAME
Name: argocd.dev
Target: <AWS_ALB_DNS_NAME>
Proxy Status: Proxied (Orange Cloud)
TTL: Auto

Type: CNAME
Name: grafana.dev
Target: <AWS_ALB_DNS_NAME>
Proxy Status: Proxied (Orange Cloud)
TTL: Auto

Type: CNAME
Name: tools.dev
Target: <AWS_ALB_DNS_NAME>
Proxy Status: Proxied (Orange Cloud)
TTL: Auto
```

### Staging Environment (staging)

```
Type: CNAME
Name: staging
Target: <AWS_STAGING_ALB_DNS_NAME>
Proxy Status: Proxied (Orange Cloud)
TTL: Auto

Type: CNAME
Name: api.staging
Target: <AWS_STAGING_ALB_DNS_NAME>
Proxy Status: Proxied (Orange Cloud)
TTL: Auto

Type: CNAME
Name: app.staging
Target: <AWS_STAGING_ALB_DNS_NAME>
Proxy Status: Proxied (Orange Cloud)
TTL: Auto
```

### Production Environment

```
Type: CNAME
Name: app
Target: <AWS_PROD_ALB_DNS_NAME>
Proxy Status: Proxied (Orange Cloud)
TTL: Auto

Type: CNAME
Name: api
Target: <AWS_PROD_ALB_DNS_NAME>
Proxy Status: Proxied (Orange Cloud)
TTL: Auto

Type: CNAME
Name: www
Target: <AWS_PROD_ALB_DNS_NAME>
Proxy Status: Proxied (Orange Cloud)
TTL: Auto
```

## SSL/TLS Configuration in Cloudflare Enterprise

### Enterprise SSL/TLS Features

1. **SSL/TLS Mode**: Full (Strict)
   - Navigate to SSL/TLS > Overview
   - Set encryption mode to "Full (strict)"
   - Enterprise includes advanced certificate management

2. **Advanced Certificate Manager**
   - Enterprise includes ACM with custom certificates
   - Automatic certificate provisioning and renewal
   - Extended validation (EV) certificates available

3. **Origin Server Certificates**
   - Navigate to SSL/TLS > Origin Server
   - Create an origin certificate for your AWS ALB
   - Enterprise provides longer validity periods and enhanced security

### Security Headers

Configure these security headers in Cloudflare:

```
Transform Rules > Modify Response Header

Header Name: Strict-Transport-Security
Value: max-age=31536000; includeSubDomains; preload

Header Name: X-Content-Type-Options
Value: nosniff

Header Name: X-Frame-Options
Value: DENY

Header Name: X-XSS-Protection
Value: 1; mode=block

Header Name: Referrer-Policy
Value: strict-origin-when-cross-origin
```

## Cloudflare Page Rules (Optional)

For additional performance and security:

1. **Cache Everything for Static Assets**
   ```
   URL: *.advancedblockchainsecurity.com/static/*
   Settings: Cache Level = Cache Everything, Edge Cache TTL = 1 month
   ```

2. **Redirect HTTP to HTTPS**
   ```
   URL: http://*advancedblockchainsecurity.com/*
   Settings: Always Use HTTPS
   ```

## Enterprise WAF Configuration

Cloudflare Enterprise WAF provides advanced security features:

### Enterprise WAF Features
1. Navigate to Security > WAF
2. Enterprise includes:
   - Advanced Managed Rulesets with real-time updates
   - Cloudflare OWASP Core Ruleset with enhanced detection
   - Exposed Credentials Check with enterprise threat intelligence
   - Custom Rules with advanced pattern matching
   - Rate Limiting with sophisticated algorithms
   - Bot Management with behavioral analysis

### Advanced Security Policies
- **Zero Trust Access**: Application-level access controls
- **DDoS Protection**: Enterprise-grade volumetric and application-layer protection
- **Advanced Rate Limiting**: Per-endpoint and user-based limiting
- **API Security**: Specialized protection for API endpoints

## Enterprise Rate Limiting

Cloudflare Enterprise provides advanced rate limiting capabilities:

### Advanced Rate Limiting Rules
1. Navigate to Security > Rate Limiting
2. Enterprise rules support:
   - **API endpoints**: 100 requests per minute per IP with burst allowance
   - **Authentication endpoints**: 5 requests per minute per IP with account-based tracking
   - **General application**: 300 requests per minute per IP with geographic variations
   - **Per-User Rate Limiting**: Track authenticated users across sessions
   - **Dynamic Rate Limiting**: Adjust limits based on threat intelligence

## Deployment Steps

1. **Deploy AWS Infrastructure**
   ```bash
   cd terraform/environments/dev
   terraform init
   terraform plan
   terraform apply
   ```

2. **Get ALB DNS Name**
   ```bash
   terraform output | grep alb_dns_name
   ```

3. **Configure DNS in Cloudflare**
   - Log into Cloudflare dashboard
   - Select your domain
   - Add the CNAME records listed above
   - Replace `<AWS_ALB_DNS_NAME>` with actual ALB DNS name

4. **Test DNS Resolution**
   ```bash
   nslookup dev.advancedblockchainsecurity.com
   nslookup api.dev.advancedblockchainsecurity.com
   ```

5. **Verify SSL**
   ```bash
   curl -I https://dev.advancedblockchainsecurity.com
   ```

## Important Notes

- **Simplified Certificate Management**: Cloudflare Enterprise handles all SSL/TLS certificates automatically - no need for cert-manager or Let's Encrypt configuration
- **Origin IP Protection**: Cloudflare Enterprise includes advanced origin protection to restrict traffic to only Cloudflare IPs
- **SSL Mode**: Use "Full (Strict)" to ensure end-to-end encryption between Cloudflare and your AWS infrastructure
- **No AWS WAF Needed**: Cloudflare Enterprise WAF provides superior protection compared to AWS WAF
- **Global CDN**: Enterprise includes global content delivery with intelligent routing

## Enterprise Monitoring & Analytics

Cloudflare Enterprise provides comprehensive monitoring capabilities:

### Advanced Analytics
- **Real-time Traffic Analytics**: Detailed traffic patterns and geographic distribution
- **Security Analytics**: Advanced threat detection and mitigation reporting
- **Performance Metrics**: Core Web Vitals, load times, and optimization opportunities
- **Cache Analytics**: Hit ratios, bandwidth savings, and cache performance
- **Bot Analytics**: Bot traffic analysis and management insights

### Enterprise Reporting
- **Custom Dashboards**: Create tailored views for different stakeholders
- **API Access**: Programmatic access to all analytics data
- **Alerting**: Advanced alerting on security events and performance issues
- **Compliance Reporting**: Detailed logs for compliance and audit requirements

### Integration Benefits
This Enterprise configuration provides:
- **99.99% Uptime SLA**: Enterprise-grade reliability guarantees
- **Global Performance**: Optimized routing and caching worldwide
- **Advanced Security**: WAF, DDoS protection, and Zero Trust access controls
- **Simplified Management**: Unified security and performance management
- **Cost Optimization**: Reduced AWS costs by eliminating WAF, CloudFront, and Route53 services

With Cloudflare Enterprise handling security, performance, and reliability at the edge, your AWS infrastructure can focus on application logic and data processing.