# IAM Module Outputs

output "aws_load_balancer_controller_role_arn" {
  description = "ARN of AWS Load Balancer Controller IAM role"
  value       = aws_iam_role.aws_load_balancer_controller.arn
}

output "ebs_csi_driver_role_arn" {
  description = "ARN of EBS CSI Driver IAM role"
  value       = aws_iam_role.ebs_csi_driver.arn
}

output "external_secrets_role_arn" {
  description = "ARN of External Secrets Operator IAM role"
  value       = aws_iam_role.external_secrets.arn
}

output "cert_manager_role_arn" {
  description = "ARN of cert-manager IAM role (disabled - using Cloudflare Enterprise)"
  value       = null
}

output "cluster_autoscaler_role_arn" {
  description = "ARN of cluster autoscaler IAM role"
  value       = var.enable_cluster_autoscaler_role ? aws_iam_role.cluster_autoscaler[0].arn : null
}

output "app_service_account_role_arns" {
  description = "ARNs of application service account IAM roles"
  value = {
    for name, role in aws_iam_role.app_service_accounts : name => role.arn
  }
}

# Service account role names for easier reference
output "service_account_role_names" {
  description = "Names of all service account IAM roles"
  value = {
    aws_load_balancer_controller = aws_iam_role.aws_load_balancer_controller.name
    ebs_csi_driver              = aws_iam_role.ebs_csi_driver.name
    external_secrets            = aws_iam_role.external_secrets.name
    cert_manager                = null  # Disabled - using Cloudflare Enterprise
    cluster_autoscaler          = var.enable_cluster_autoscaler_role ? aws_iam_role.cluster_autoscaler[0].name : null
  }
}

# Consolidated output for all IAM role ARNs
output "all_role_arns" {
  description = "Map of all IAM role ARNs"
  value = merge(
    {
      aws_load_balancer_controller = aws_iam_role.aws_load_balancer_controller.arn
      ebs_csi_driver              = aws_iam_role.ebs_csi_driver.arn
      external_secrets            = aws_iam_role.external_secrets.arn
      cert_manager                = null  # Disabled - using Cloudflare Enterprise
      cluster_autoscaler          = var.enable_cluster_autoscaler_role ? aws_iam_role.cluster_autoscaler[0].arn : null
    },
    {
      for name, role in aws_iam_role.app_service_accounts : name => role.arn
    }
  )
}