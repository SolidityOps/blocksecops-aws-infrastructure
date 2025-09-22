# Staging Environment Outputs

# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.vpc.private_subnet_ids
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnet_ids
}

output "database_subnet_ids" {
  description = "IDs of the database subnets"
  value       = module.vpc.database_subnet_ids
}

# EKS Outputs
output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
  sensitive   = true
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = module.eks.cluster_security_group_id
}

output "cluster_iam_role_arn" {
  description = "IAM role ARN associated with EKS cluster"
  value       = module.eks.cluster_iam_role_arn
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC Provider if one is created"
  value       = module.eks.oidc_provider_arn
}

output "node_groups" {
  description = "EKS node groups"
  value       = module.eks.node_groups
}

# RDS Outputs
output "db_instance_endpoint" {
  description = "RDS instance endpoint"
  value       = module.rds.db_endpoint
  sensitive   = true
}

output "db_instance_id" {
  description = "RDS instance ID"
  value       = module.rds.db_instance_id
}

output "db_instance_port" {
  description = "RDS instance port"
  value       = module.rds.db_port
}

output "db_subnet_group_name" {
  description = "RDS subnet group name"
  value       = module.rds.db_subnet_group_name
}

# ElastiCache Outputs
output "elasticache_cluster_id" {
  description = "ElastiCache cluster ID"
  value       = module.elasticache.cluster_id
}

output "elasticache_cluster_address" {
  description = "ElastiCache cluster address"
  value       = module.elasticache.cluster_address
  sensitive   = true
}

output "elasticache_cluster_port" {
  description = "ElastiCache cluster port"
  value       = module.elasticache.cluster_port
}

# ECR Outputs
output "ecr_repository_urls" {
  description = "URLs of the ECR repositories"
  value       = module.ecr.repository_urls
}

output "ecr_repository_arns" {
  description = "ARNs of the ECR repositories"
  value       = module.ecr.repository_arns
}

# IAM Outputs
output "aws_load_balancer_controller_role_arn" {
  description = "ARN of AWS Load Balancer Controller IAM role"
  value       = module.iam.aws_load_balancer_controller_role_arn
}

output "ebs_csi_driver_role_arn" {
  description = "ARN of EBS CSI Driver IAM role"
  value       = module.iam.ebs_csi_driver_role_arn
}

output "external_secrets_role_arn" {
  description = "ARN of External Secrets Operator IAM role"
  value       = module.iam.external_secrets_role_arn
}

output "cluster_autoscaler_role_arn" {
  description = "ARN of cluster autoscaler IAM role"
  value       = module.iam.cluster_autoscaler_role_arn
}

output "app_service_account_role_arns" {
  description = "ARNs of application service account IAM roles"
  value       = module.iam.app_service_account_role_arns
}

# Secrets Manager Outputs
output "database_secret_arn" {
  description = "ARN of the database secret"
  value       = module.secrets_manager.database_secret_arn
  sensitive   = true
}

output "elasticache_secret_arn" {
  description = "ARN of the ElastiCache secret"
  value       = module.secrets_manager.elasticache_secret_arn
  sensitive   = true
}

# Security Groups Outputs
output "eks_cluster_security_group_id" {
  description = "Security group ID for EKS cluster"
  value       = module.security_groups.eks_cluster_security_group_id
}

output "eks_node_security_group_id" {
  description = "Security group ID for EKS nodes"
  value       = module.security_groups.eks_node_security_group_id
}

output "alb_security_group_id" {
  description = "Security group ID for Application Load Balancer"
  value       = module.security_groups.alb_security_group_id
}

output "rds_security_group_id" {
  description = "Security group ID for RDS"
  value       = module.security_groups.rds_security_group_id
}

output "elasticache_security_group_id" {
  description = "Security group ID for ElastiCache"
  value       = module.security_groups.elasticache_security_group_id
}

# Environment Information
output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "region" {
  description = "AWS region"
  value       = var.aws_region
}

output "project_name" {
  description = "Project name"
  value       = var.project_name
}