# Development Environment Outputs

# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.vpc.private_subnet_ids
}

output "database_subnet_ids" {
  description = "IDs of the database subnets"
  value       = module.vpc.database_subnet_ids
}

# EKS Outputs
output "cluster_id" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_id
}

output "cluster_arn" {
  description = "ARN of the EKS cluster"
  value       = module.eks.cluster_arn
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = module.eks.cluster_security_group_id
}

output "cluster_iam_role_arn" {
  description = "IAM role ARN associated with EKS cluster"
  value       = module.eks.cluster_iam_role_arn
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC provider for the EKS cluster"
  value       = module.eks.oidc_provider_arn
}

output "node_group_arn" {
  description = "ARN of the EKS node group"
  value       = module.eks.node_group_arn
}

# RDS Outputs
output "rds_instance_id" {
  description = "RDS instance ID"
  value       = module.rds.db_instance_id
}

output "rds_instance_endpoint" {
  description = "RDS instance connection endpoint"
  value       = module.rds.db_instance_endpoint
}

output "rds_instance_arn" {
  description = "RDS instance ARN"
  value       = module.rds.db_instance_arn
}

output "rds_secrets_manager_secret_arn" {
  description = "ARN of Secrets Manager secret containing RDS credentials"
  value       = module.rds.secrets_manager_secret_arn
}

# ElastiCache Outputs
output "redis_primary_endpoint" {
  description = "Redis primary endpoint"
  value       = module.elasticache.primary_endpoint_address
}

output "redis_port" {
  description = "Redis port"
  value       = module.elasticache.port
}

output "redis_secrets_manager_secret_arn" {
  description = "ARN of Secrets Manager secret containing Redis auth token"
  value       = module.elasticache.secrets_manager_secret_arn
}

# ECR Outputs
output "ecr_repository_urls" {
  description = "URLs of ECR repositories"
  value       = module.ecr.repository_urls
}

output "ecr_repository_arns" {
  description = "ARNs of ECR repositories"
  value       = module.ecr.repository_arns
}

# Security Group Outputs
output "eks_security_group_id" {
  description = "Security group ID for EKS cluster"
  value       = module.security_groups.eks_security_group_id
}

output "rds_security_group_id" {
  description = "Security group ID for RDS"
  value       = module.security_groups.rds_security_group_id
}

output "elasticache_security_group_id" {
  description = "Security group ID for ElastiCache"
  value       = module.security_groups.elasticache_security_group_id
}

# KMS Outputs
output "kms_key_id" {
  description = "KMS key ID"
  value       = aws_kms_key.main.key_id
}

output "kms_key_arn" {
  description = "KMS key ARN"
  value       = aws_kms_key.main.arn
}

output "kms_alias_arn" {
  description = "KMS alias ARN"
  value       = aws_kms_alias.main.arn
}

# Secrets Manager Outputs
output "secrets_manager_secret_arns" {
  description = "ARNs of all Secrets Manager secrets"
  value       = module.secrets_manager.secret_arns
}

output "secrets_access_policy_arn" {
  description = "ARN of IAM policy for accessing secrets"
  value       = module.secrets_manager.secrets_access_policy_arn
}

# Connection Information for Applications
output "database_connection_info" {
  description = "Database connection information"
  value = {
    endpoint    = module.rds.db_instance_endpoint
    port        = module.rds.db_instance_port
    database    = module.rds.db_instance_name
    username    = module.rds.db_instance_username
    secret_arn  = module.rds.secrets_manager_secret_arn
  }
}

output "redis_connection_info" {
  description = "Redis connection information"
  value = {
    endpoint   = module.elasticache.primary_endpoint_address
    port       = module.elasticache.port
    ssl        = true
    secret_arn = module.elasticache.secrets_manager_secret_arn
  }
}

# Domain Configuration
output "domain_name" {
  description = "Domain name for this environment"
  value       = "${var.subdomain_prefix}.${var.domain_name}"
}

# Kubeconfig information
output "kubeconfig_command" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_id}"
}

# Environment summary
output "environment_summary" {
  description = "Summary of deployed resources"
  value = {
    environment = var.environment
    region      = var.aws_region
    vpc_id      = module.vpc.vpc_id
    cluster_name = module.eks.cluster_id
    domain      = "${var.subdomain_prefix}.${var.domain_name}"

    endpoints = {
      eks_api        = module.eks.cluster_endpoint
      rds_endpoint   = module.rds.db_instance_endpoint
      redis_endpoint = module.elasticache.primary_endpoint_address
    }

    security = {
      kms_key_id = aws_kms_key.main.key_id
      secrets_in_secrets_manager = length(module.secrets_manager.secret_arns)
    }
  }
}