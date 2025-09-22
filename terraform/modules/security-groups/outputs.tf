# Security Groups Module Outputs

output "eks_cluster_security_group_id" {
  description = "Security group ID for EKS cluster"
  value       = aws_security_group.eks_cluster.id
}

output "eks_nodes_security_group_id" {
  description = "Security group ID for EKS worker nodes"
  value       = aws_security_group.eks_nodes.id
}

output "alb_security_group_id" {
  description = "Security group ID for Application Load Balancer"
  value       = aws_security_group.alb.id
}

output "rds_security_group_id" {
  description = "Security group ID for RDS"
  value       = aws_security_group.rds.id
}

output "elasticache_security_group_id" {
  description = "Security group ID for ElastiCache"
  value       = aws_security_group.elasticache.id
}

output "lambda_security_group_id" {
  description = "Security group ID for Lambda functions"
  value       = aws_security_group.lambda.id
}

output "bastion_security_group_id" {
  description = "Security group ID for bastion host"
  value       = var.enable_bastion_access ? aws_security_group.bastion[0].id : null
}

output "vpc_endpoints_security_group_id" {
  description = "Security group ID for VPC endpoints"
  value       = aws_security_group.vpc_endpoints.id
}

# Consolidated output for easier reference
output "security_group_ids" {
  description = "Map of all security group IDs"
  value = {
    eks_cluster   = aws_security_group.eks_cluster.id
    eks_nodes     = aws_security_group.eks_nodes.id
    alb           = aws_security_group.alb.id
    rds           = aws_security_group.rds.id
    elasticache   = aws_security_group.elasticache.id
    lambda        = aws_security_group.lambda.id
    bastion       = var.enable_bastion_access ? aws_security_group.bastion[0].id : null
    vpc_endpoints = aws_security_group.vpc_endpoints.id
  }
}