# Cloudflare DNS Infrastructure for Advanced Blockchain Security
# Domain: advancedblockchainsecurity.com

terraform {
  required_version = ">= 1.0"
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}

# Configure Cloudflare provider
provider "cloudflare" {
  # API token should be set via CLOUDFLARE_API_TOKEN environment variable
  # Zone ID should be set via CLOUDFLARE_ZONE_ID environment variable
}

# Data source for the existing zone
data "cloudflare_zone" "main" {
  name = var.domain_name
}

# Main domain A record (points to production load balancer)
resource "cloudflare_record" "root_domain" {
  zone_id = data.cloudflare_zone.main.id
  name    = var.domain_name
  value   = var.production_lb_ip
  type    = "A"
  ttl     = 300
  proxied = true

  comment = "Root domain pointing to production environment"
}

# WWW redirect to root domain
resource "cloudflare_record" "www" {
  zone_id = data.cloudflare_zone.main.id
  name    = "www"
  value   = var.domain_name
  type    = "CNAME"
  ttl     = 300
  proxied = true

  comment = "WWW redirect to root domain"
}

# Staging environment subdomain
resource "cloudflare_record" "staging" {
  zone_id = data.cloudflare_zone.main.id
  name    = "staging"
  value   = var.staging_lb_ip
  type    = "A"
  ttl     = 300
  proxied = true

  comment = "Staging environment for development and testing"
}

# API subdomain for production
resource "cloudflare_record" "api" {
  zone_id = data.cloudflare_zone.main.id
  name    = "api"
  value   = var.production_lb_ip
  type    = "A"
  ttl     = 300
  proxied = true

  comment = "Production API endpoint"
}

# API staging subdomain
resource "cloudflare_record" "api_staging" {
  zone_id = data.cloudflare_zone.main.id
  name    = "api-staging"
  value   = var.staging_lb_ip
  type    = "A"
  ttl     = 300
  proxied = true

  comment = "Staging API endpoint"
}

# Dashboard subdomain for production
resource "cloudflare_record" "dashboard" {
  zone_id = data.cloudflare_zone.main.id
  name    = "dashboard"
  value   = var.production_lb_ip
  type    = "A"
  ttl     = 300
  proxied = true

  comment = "Production dashboard interface"
}

# Dashboard staging subdomain
resource "cloudflare_record" "dashboard_staging" {
  zone_id = data.cloudflare_zone.main.id
  name    = "dashboard-staging"
  value   = var.staging_lb_ip
  type    = "A"
  ttl     = 300
  proxied = true

  comment = "Staging dashboard interface"
}

# Vault subdomain for secure secret management
resource "cloudflare_record" "vault" {
  zone_id = data.cloudflare_zone.main.id
  name    = "vault"
  value   = var.production_lb_ip
  type    = "A"
  ttl     = 300
  proxied = false  # Direct access for Vault UI

  comment = "HashiCorp Vault UI access"
}

# Vault staging subdomain
resource "cloudflare_record" "vault_staging" {
  zone_id = data.cloudflare_zone.main.id
  name    = "vault-staging"
  value   = var.staging_lb_ip
  type    = "A"
  ttl     = 300
  proxied = false  # Direct access for Vault UI

  comment = "HashiCorp Vault staging UI access"
}

# ArgoCD subdomain for GitOps management
resource "cloudflare_record" "argocd" {
  zone_id = data.cloudflare_zone.main.id
  name    = "argocd"
  value   = var.production_lb_ip
  type    = "A"
  ttl     = 300
  proxied = true

  comment = "ArgoCD GitOps management interface"
}

# ArgoCD staging subdomain
resource "cloudflare_record" "argocd_staging" {
  zone_id = data.cloudflare_zone.main.id
  name    = "argocd-staging"
  value   = var.staging_lb_ip
  type    = "A"
  ttl     = 300
  proxied = true

  comment = "ArgoCD staging GitOps management interface"
}

# Monitoring subdomain (Grafana/Prometheus)
resource "cloudflare_record" "monitoring" {
  zone_id = data.cloudflare_zone.main.id
  name    = "monitoring"
  value   = var.production_lb_ip
  type    = "A"
  ttl     = 300
  proxied = true

  comment = "Monitoring dashboard (Grafana/Prometheus)"
}

# Monitoring staging subdomain
resource "cloudflare_record" "monitoring_staging" {
  zone_id = data.cloudflare_zone.main.id
  name    = "monitoring-staging"
  value   = var.staging_lb_ip
  type    = "A"
  ttl     = 300
  proxied = true

  comment = "Staging monitoring dashboard"
}

# Email MX records (if needed for notifications)
resource "cloudflare_record" "mx" {
  zone_id  = data.cloudflare_zone.main.id
  name     = var.domain_name
  value    = "mail.advancedblockchainsecurity.com"
  type     = "MX"
  priority = 10
  ttl      = 3600

  comment = "Primary mail exchange"
}

# SPF record for email security
resource "cloudflare_record" "spf" {
  zone_id = data.cloudflare_zone.main.id
  name    = var.domain_name
  value   = "v=spf1 include:_spf.google.com ~all"
  type    = "TXT"
  ttl     = 3600

  comment = "SPF record for email security"
}

# DMARC record for email security
resource "cloudflare_record" "dmarc" {
  zone_id = data.cloudflare_zone.main.id
  name    = "_dmarc"
  value   = "v=DMARC1; p=quarantine; rua=mailto:dmarc@advancedblockchainsecurity.com"
  type    = "TXT"
  ttl     = 3600

  comment = "DMARC policy for email security"
}

# Cloudflare security settings
resource "cloudflare_zone_settings_override" "security" {
  zone_id = data.cloudflare_zone.main.id

  settings {
    # SSL/TLS settings
    ssl                      = "strict"
    always_use_https        = "on"
    min_tls_version         = "1.2"
    tls_1_3                 = "on"
    automatic_https_rewrites = "on"

    # Security settings
    security_level          = "medium"
    challenge_ttl           = 1800
    browser_check           = "on"
    hotlink_protection      = "on"
    email_obfuscation       = "on"
    server_side_exclude     = "on"

    # Performance settings
    brotli                  = "on"
    minify {
      css  = "on"
      js   = "on"
      html = "on"
    }

    # Caching settings
    browser_cache_ttl       = 14400
    always_online           = "on"
    development_mode        = "off"
  }
}