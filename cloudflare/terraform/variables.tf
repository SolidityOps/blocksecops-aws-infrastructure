# Variables for Cloudflare DNS Configuration

variable "domain_name" {
  description = "The primary domain name"
  type        = string
  default     = "advancedblockchainsecurity.com"
}

variable "production_lb_ip" {
  description = "Production load balancer IP address"
  type        = string
  default     = "1.2.3.4"  # Placeholder - will be updated after AWS ALB deployment
}

variable "staging_lb_ip" {
  description = "Staging load balancer IP address"
  type        = string
  default     = "5.6.7.8"  # Placeholder - will be updated after AWS ALB deployment
}

variable "cloudflare_zone_id" {
  description = "Cloudflare Zone ID for the domain"
  type        = string
  sensitive   = true
}

variable "cloudflare_api_token" {
  description = "Cloudflare API token for DNS management"
  type        = string
  sensitive   = true
}

# Environment-specific configurations
variable "staging_config" {
  description = "Staging environment DNS configuration"
  type = object({
    subdomain = string
    ttl       = number
    proxied   = bool
  })
  default = {
    subdomain = "staging"
    ttl       = 300
    proxied   = true
  }
}

variable "production_config" {
  description = "Production environment DNS configuration"
  type = object({
    subdomain = string
    ttl       = number
    proxied   = bool
  })
  default = {
    subdomain = "app"
    ttl       = 300
    proxied   = true
  }
}

# Service-specific configurations
variable "services" {
  description = "Service-specific DNS configurations"
  type = map(object({
    enabled     = bool
    subdomain   = string
    environment = string
    proxied     = bool
    ttl         = number
  }))
  default = {
    api = {
      enabled     = true
      subdomain   = "api"
      environment = "production"
      proxied     = true
      ttl         = 300
    }
    dashboard = {
      enabled     = true
      subdomain   = "dashboard"
      environment = "production"
      proxied     = true
      ttl         = 300
    }
    vault = {
      enabled     = true
      subdomain   = "vault"
      environment = "production"
      proxied     = false
      ttl         = 300
    }
    argocd = {
      enabled     = true
      subdomain   = "argocd"
      environment = "production"
      proxied     = true
      ttl         = 300
    }
    monitoring = {
      enabled     = true
      subdomain   = "monitoring"
      environment = "production"
      proxied     = true
      ttl         = 300
    }
  }
}

# SSL/TLS configuration
variable "ssl_config" {
  description = "SSL/TLS configuration settings"
  type = object({
    ssl_mode             = string
    min_tls_version      = string
    tls_1_3              = string
    always_use_https     = string
    automatic_https_rewrites = string
  })
  default = {
    ssl_mode             = "strict"
    min_tls_version      = "1.2"
    tls_1_3              = "on"
    always_use_https     = "on"
    automatic_https_rewrites = "on"
  }
}

# Security configuration
variable "security_config" {
  description = "Cloudflare security configuration"
  type = object({
    security_level      = string
    challenge_ttl       = number
    browser_check       = string
    hotlink_protection  = string
    email_obfuscation   = string
  })
  default = {
    security_level      = "medium"
    challenge_ttl       = 1800
    browser_check       = "on"
    hotlink_protection  = "on"
    email_obfuscation   = "on"
  }
}

# Performance configuration
variable "performance_config" {
  description = "Cloudflare performance optimization settings"
  type = object({
    brotli              = string
    minify_css          = string
    minify_js           = string
    minify_html         = string
    browser_cache_ttl   = number
    always_online       = string
  })
  default = {
    brotli              = "on"
    minify_css          = "on"
    minify_js           = "on"
    minify_html         = "on"
    browser_cache_ttl   = 14400
    always_online       = "on"
  }
}