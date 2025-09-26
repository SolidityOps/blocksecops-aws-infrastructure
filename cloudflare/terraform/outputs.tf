# Outputs for Cloudflare DNS Configuration

output "zone_id" {
  description = "Cloudflare Zone ID"
  value       = data.cloudflare_zone.main.id
}

output "zone_name" {
  description = "Zone name"
  value       = data.cloudflare_zone.main.name
}

output "nameservers" {
  description = "Cloudflare nameservers for the zone"
  value       = data.cloudflare_zone.main.name_servers
}

# DNS record outputs
output "dns_records" {
  description = "DNS records created"
  value = {
    root_domain = {
      name  = cloudflare_record.root_domain.name
      value = cloudflare_record.root_domain.value
      type  = cloudflare_record.root_domain.type
    }
    staging = {
      name  = cloudflare_record.staging.name
      value = cloudflare_record.staging.value
      type  = cloudflare_record.staging.type
    }
    api = {
      name  = cloudflare_record.api.name
      value = cloudflare_record.api.value
      type  = cloudflare_record.api.type
    }
    api_staging = {
      name  = cloudflare_record.api_staging.name
      value = cloudflare_record.api_staging.value
      type  = cloudflare_record.api_staging.type
    }
    dashboard = {
      name  = cloudflare_record.dashboard.name
      value = cloudflare_record.dashboard.value
      type  = cloudflare_record.dashboard.type
    }
    dashboard_staging = {
      name  = cloudflare_record.dashboard_staging.name
      value = cloudflare_record.dashboard_staging.value
      type  = cloudflare_record.dashboard_staging.type
    }
    vault = {
      name  = cloudflare_record.vault.name
      value = cloudflare_record.vault.value
      type  = cloudflare_record.vault.type
    }
    vault_staging = {
      name  = cloudflare_record.vault_staging.name
      value = cloudflare_record.vault_staging.value
      type  = cloudflare_record.vault_staging.type
    }
    argocd = {
      name  = cloudflare_record.argocd.name
      value = cloudflare_record.argocd.value
      type  = cloudflare_record.argocd.type
    }
    argocd_staging = {
      name  = cloudflare_record.argocd_staging.name
      value = cloudflare_record.argocd_staging.value
      type  = cloudflare_record.argocd_staging.type
    }
    monitoring = {
      name  = cloudflare_record.monitoring.name
      value = cloudflare_record.monitoring.value
      type  = cloudflare_record.monitoring.type
    }
    monitoring_staging = {
      name  = cloudflare_record.monitoring_staging.name
      value = cloudflare_record.monitoring_staging.value
      type  = cloudflare_record.monitoring_staging.type
    }
  }
  sensitive = false
}

# Service endpoints
output "service_endpoints" {
  description = "Service endpoints for different environments"
  value = {
    production = {
      root        = "https://${var.domain_name}"
      api         = "https://api.${var.domain_name}"
      dashboard   = "https://dashboard.${var.domain_name}"
      vault       = "https://vault.${var.domain_name}"
      argocd      = "https://argocd.${var.domain_name}"
      monitoring  = "https://monitoring.${var.domain_name}"
    }
    staging = {
      root        = "https://staging.${var.domain_name}"
      api         = "https://api-staging.${var.domain_name}"
      dashboard   = "https://dashboard-staging.${var.domain_name}"
      vault       = "https://vault-staging.${var.domain_name}"
      argocd      = "https://argocd-staging.${var.domain_name}"
      monitoring  = "https://monitoring-staging.${var.domain_name}"
    }
  }
}

# SSL certificate validation domains
output "ssl_validation_domains" {
  description = "Domains that will need SSL certificate validation"
  value = [
    var.domain_name,
    "www.${var.domain_name}",
    "staging.${var.domain_name}",
    "api.${var.domain_name}",
    "api-staging.${var.domain_name}",
    "dashboard.${var.domain_name}",
    "dashboard-staging.${var.domain_name}",
    "vault.${var.domain_name}",
    "vault-staging.${var.domain_name}",
    "argocd.${var.domain_name}",
    "argocd-staging.${var.domain_name}",
    "monitoring.${var.domain_name}",
    "monitoring-staging.${var.domain_name}"
  ]
}

# Zone settings
output "zone_settings" {
  description = "Applied zone settings"
  value = {
    ssl_mode         = "strict"
    min_tls_version  = "1.2"
    security_level   = "medium"
    always_use_https = "on"
  }
  sensitive = false
}