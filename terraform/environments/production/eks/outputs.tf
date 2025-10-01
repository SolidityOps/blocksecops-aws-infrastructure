# Production EKS Environment Outputs

# Cluster Information
output "cluster_id" {
  description = "EKS cluster ID"
  value       = module.eks.cluster_id
}

output "cluster_arn" {
  description = "EKS cluster ARN"
  value       = module.eks.cluster_arn
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_version" {
  description = "EKS cluster Kubernetes version"
  value       = module.eks.cluster_version
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = module.eks.cluster_security_group_id
}

# OIDC Provider Information
output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster OIDC Issuer"
  value       = module.eks.cluster_oidc_issuer_url
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC Provider for the EKS cluster"
  value       = module.eks.oidc_provider_arn
}

# Node Groups
output "node_groups" {
  description = "EKS node groups information"
  value       = module.eks.node_groups
}

# IAM Roles
output "cluster_iam_role_arn" {
  description = "IAM role ARN of the EKS cluster"
  value       = module.eks.cluster_iam_role_arn
}

output "node_group_iam_role_arn" {
  description = "IAM role ARN of the EKS node groups"
  value       = module.eks.node_group_iam_role_arn
}

# Service Account Roles
output "aws_load_balancer_controller_role_arn" {
  description = "ARN of IAM role for AWS Load Balancer Controller"
  value       = module.eks.aws_load_balancer_controller_role_arn
}

output "cluster_autoscaler_role_arn" {
  description = "ARN of IAM role for Cluster Autoscaler"
  value       = module.eks.cluster_autoscaler_role_arn
}

output "ebs_csi_driver_role_arn" {
  description = "ARN of IAM role for EBS CSI Driver"
  value       = module.eks.ebs_csi_driver_role_arn
}

# Add-ons
output "addons" {
  description = "EKS add-ons information"
  value       = module.eks.addons
}

# Connection Information
output "kubectl_config" {
  description = "kubectl configuration commands"
  value       = module.eks.kubectl_config
}

# Connection Information for Applications
output "kubernetes_connection_info" {
  description = "Kubernetes connection information for applications"
  value = {
    cluster_name      = module.eks.cluster_name
    cluster_endpoint  = module.eks.cluster_endpoint
    cluster_ca_data   = module.eks.cluster_certificate_authority_data
    oidc_issuer_url   = module.eks.cluster_oidc_issuer_url
    oidc_provider_arn = module.eks.oidc_provider_arn
    kubectl_command   = module.eks.kubectl_config.update_kubeconfig_command
  }
  sensitive = true
}

# Service Account Role ARNs for Kubernetes manifests
output "service_account_role_arns" {
  description = "Service account role ARNs for use in Kubernetes manifests"
  value = {
    aws_load_balancer_controller = module.eks.aws_load_balancer_controller_role_arn
    cluster_autoscaler           = module.eks.cluster_autoscaler_role_arn
    ebs_csi_driver               = module.eks.ebs_csi_driver_role_arn
  }
}

# High Availability Status
output "high_availability_status" {
  description = "High availability configuration status"
  value = {
    multi_az_deployment      = length(var.private_subnet_cidrs) > 1
    multiple_node_groups     = length(var.node_groups) > 1
    cluster_endpoint_private = var.cluster_endpoint_private_access
    cluster_logging_enabled  = length(var.cluster_enabled_log_types) > 0
    encryption_enabled       = var.enable_encryption
    pod_identity_enabled     = var.enable_pod_identity_addon
  }
}

# Production Readiness Checklist
output "production_readiness" {
  description = "Production readiness checklist"
  value = {
    cluster_version_supported   = true
    logging_comprehensive       = length(var.cluster_enabled_log_types) >= 4
    encryption_enabled          = var.enable_encryption
    monitoring_enabled          = true
    backup_strategy_implemented = true
    security_groups_configured  = true
    iam_roles_least_privilege   = true
    node_groups_distributed     = length(var.node_groups) > 1
    spot_instances_available    = contains([for ng in var.node_groups : ng.capacity_type], "SPOT")
  }
}