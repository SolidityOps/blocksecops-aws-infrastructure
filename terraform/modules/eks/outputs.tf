# EKS Module Outputs
# Outputs for EKS cluster and node group information

# Cluster Outputs
output "cluster_id" {
  description = "The ID of the EKS cluster"
  value       = aws_eks_cluster.main.id
}

output "cluster_arn" {
  description = "The Amazon Resource Name (ARN) of the cluster"
  value       = aws_eks_cluster.main.arn
}

output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_version" {
  description = "The Kubernetes version for the EKS cluster"
  value       = aws_eks_cluster.main.version
}

output "cluster_platform_version" {
  description = "Platform version for the EKS cluster"
  value       = aws_eks_cluster.main.platform_version
}

output "cluster_status" {
  description = "Status of the EKS cluster"
  value       = aws_eks_cluster.main.status
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = aws_eks_cluster.main.certificate_authority[0].data
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = aws_security_group.cluster.id
}

output "cluster_iam_role_arn" {
  description = "IAM role ARN of the EKS cluster"
  value       = aws_iam_role.cluster.arn
}

output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster for the OpenID Connect identity provider"
  value       = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

output "cluster_primary_security_group_id" {
  description = "The cluster primary security group ID created by EKS"
  value       = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
}

# CloudWatch Log Group
output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group for cluster logs"
  value       = aws_cloudwatch_log_group.cluster.name
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch log group for cluster logs"
  value       = aws_cloudwatch_log_group.cluster.arn
}

# Node Group Outputs
output "node_group_arn" {
  description = "Amazon Resource Name (ARN) of the EKS Node Group"
  value       = aws_eks_node_group.main.arn
}

output "node_group_id" {
  description = "EKS cluster name and EKS Node Group name separated by a colon"
  value       = aws_eks_node_group.main.id
}

output "node_group_status" {
  description = "Status of the EKS Node Group"
  value       = aws_eks_node_group.main.status
}

output "node_group_capacity_type" {
  description = "Type of capacity associated with the EKS Node Group"
  value       = aws_eks_node_group.main.capacity_type
}

output "node_group_instance_types" {
  description = "Set of instance types associated with the EKS Node Group"
  value       = aws_eks_node_group.main.instance_types
}

output "node_group_ami_type" {
  description = "Type of Amazon Machine Image (AMI) associated with the EKS Node Group"
  value       = aws_eks_node_group.main.ami_type
}

output "node_group_release_version" {
  description = "AMI version of the EKS Node Group"
  value       = aws_eks_node_group.main.release_version
}

output "node_group_version" {
  description = "Kubernetes version of the EKS Node Group"
  value       = aws_eks_node_group.main.version
}

output "node_security_group_id" {
  description = "Security group ID attached to the EKS node group"
  value       = aws_security_group.node_group.id
}

output "node_group_iam_role_arn" {
  description = "IAM role ARN of the EKS node group"
  value       = aws_iam_role.node_group.arn
}

output "node_group_resources" {
  description = "List of objects containing information about underlying resources of the EKS Node Group"
  value       = aws_eks_node_group.main.resources
}

# Secondary Node Group Outputs (conditional)
output "secondary_node_group_arn" {
  description = "Amazon Resource Name (ARN) of the secondary EKS Node Group"
  value       = var.create_secondary_node_group ? aws_eks_node_group.secondary[0].arn : null
}

output "secondary_node_group_id" {
  description = "EKS cluster name and secondary EKS Node Group name separated by a colon"
  value       = var.create_secondary_node_group ? aws_eks_node_group.secondary[0].id : null
}

output "secondary_node_group_status" {
  description = "Status of the secondary EKS Node Group"
  value       = var.create_secondary_node_group ? aws_eks_node_group.secondary[0].status : null
}

# Launch Template Outputs (conditional)
output "launch_template_id" {
  description = "The ID of the launch template"
  value       = var.use_launch_template ? aws_launch_template.node_group[0].id : null
}

output "launch_template_arn" {
  description = "The ARN of the launch template"
  value       = var.use_launch_template ? aws_launch_template.node_group[0].arn : null
}

output "launch_template_latest_version" {
  description = "The latest version of the launch template"
  value       = var.use_launch_template ? aws_launch_template.node_group[0].latest_version : null
}

# OIDC Identity Provider
output "oidc_provider_arn" {
  description = "The ARN of the OIDC Identity Provider"
  value       = aws_iam_openid_connect_provider.cluster.arn
}

# Cluster Autoscaler Policy
output "cluster_autoscaler_policy_arn" {
  description = "The ARN of the cluster autoscaler policy"
  value       = aws_iam_policy.cluster_autoscaler.arn
}

# Kubeconfig data for kubectl configuration
output "kubeconfig" {
  description = "kubectl config file contents for this EKS cluster"
  value = templatefile("${path.module}/kubeconfig.tpl", {
    cluster_name               = aws_eks_cluster.main.name
    endpoint                   = aws_eks_cluster.main.endpoint
    certificate_authority_data = aws_eks_cluster.main.certificate_authority[0].data
    region                     = data.aws_region.current.name
  })
  sensitive = true
}

# Data sources for additional information
data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

output "aws_account_id" {
  description = "The AWS Account ID number of the account that owns or contains the calling entity"
  value       = data.aws_caller_identity.current.account_id
}

output "aws_region" {
  description = "The AWS region where the EKS cluster is deployed"
  value       = data.aws_region.current.name
}

# CloudWatch Outputs
output "cloudwatch_log_group_node_group_name" {
  description = "Name of the CloudWatch log group for node group logs"
  value       = aws_cloudwatch_log_group.node_group.name
}

output "cloudwatch_log_group_cluster_autoscaler_name" {
  description = "Name of the CloudWatch log group for cluster autoscaler logs"
  value       = aws_cloudwatch_log_group.cluster_autoscaler.name
}

output "cloudwatch_dashboard_name" {
  description = "Name of the CloudWatch dashboard for EKS monitoring"
  value       = aws_cloudwatch_dashboard.eks_cluster.dashboard_name
}

output "cloudwatch_dashboard_url" {
  description = "URL of the CloudWatch dashboard for EKS monitoring"
  value       = "https://${data.aws_region.current.name}.console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.name}#dashboards:name=${aws_cloudwatch_dashboard.eks_cluster.dashboard_name}"
}

# Container Insights Outputs (conditional)
output "container_insights_log_groups" {
  description = "List of Container Insights log group names"
  value = var.enable_container_insights ? [
    aws_cloudwatch_log_group.container_insights_application[0].name,
    aws_cloudwatch_log_group.container_insights_dataplane[0].name,
    aws_cloudwatch_log_group.container_insights_host[0].name,
    aws_cloudwatch_log_group.container_insights_performance[0].name
  ] : []
}