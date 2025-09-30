# Outputs for production networking environment

# VPC Information
output "vpc_id" {
  description = "ID of the production VPC"
  value       = module.networking.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the production VPC"
  value       = module.networking.vpc_cidr_block
}

output "availability_zones" {
  description = "Availability zones used in production"
  value       = module.networking.availability_zones
}

# Subnet Information
output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = module.networking.private_subnet_ids
}

output "database_subnet_ids" {
  description = "IDs of database subnets"
  value       = module.networking.database_subnet_ids
}

output "public_subnet_cidr_blocks" {
  description = "CIDR blocks of public subnets"
  value       = module.networking.public_subnet_cidr_blocks
}

output "private_subnet_cidr_blocks" {
  description = "CIDR blocks of private subnets"
  value       = module.networking.private_subnet_cidr_blocks
}

output "database_subnet_cidr_blocks" {
  description = "CIDR blocks of database subnets"
  value       = module.networking.database_subnet_cidr_blocks
}

# Database Subnet Groups
output "db_subnet_group_name" {
  description = "Name of the RDS subnet group"
  value       = module.networking.db_subnet_group_name
}

output "elasticache_subnet_group_name" {
  description = "Name of the ElastiCache subnet group"
  value       = module.networking.elasticache_subnet_group_name
}

# Security Groups
output "eks_cluster_security_group_id" {
  description = "ID of the EKS cluster security group"
  value       = module.networking.eks_cluster_security_group_id
}

output "eks_nodes_security_group_id" {
  description = "ID of the EKS nodes security group"
  value       = module.networking.eks_nodes_security_group_id
}

output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = module.networking.alb_security_group_id
}

output "postgresql_security_group_id" {
  description = "ID of the PostgreSQL security group"
  value       = module.networking.postgresql_security_group_id
}

output "elasticache_security_group_id" {
  description = "ID of the ElastiCache security group"
  value       = module.networking.elasticache_security_group_id
}

output "bastion_security_group_id" {
  description = "ID of the bastion security group"
  value       = module.networking.bastion_security_group_id
}

# NAT Information
output "nat_gateway_ids" {
  description = "IDs of NAT gateways"
  value       = module.networking.nat_gateway_ids
}

output "nat_public_ips" {
  description = "Public IPs of NAT gateways"
  value       = module.networking.nat_public_ips
}

# VPC Endpoints
output "vpc_endpoint_s3_id" {
  description = "ID of the S3 VPC endpoint"
  value       = module.networking.vpc_endpoint_s3_id
}

output "vpc_endpoint_dynamodb_id" {
  description = "ID of the DynamoDB VPC endpoint"
  value       = module.networking.vpc_endpoint_dynamodb_id
}

output "vpc_endpoint_ecr_api_id" {
  description = "ID of the ECR API VPC endpoint"
  value       = module.networking.vpc_endpoint_ecr_api_id
}

output "vpc_endpoint_secrets_manager_id" {
  description = "ID of the Secrets Manager VPC endpoint"
  value       = module.networking.vpc_endpoint_secrets_manager_id
}

# Network Configuration
output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = module.networking.internet_gateway_id
}

output "public_route_table_ids" {
  description = "IDs of public route tables"
  value       = module.networking.public_route_table_ids
}

output "private_route_table_ids" {
  description = "IDs of private route tables"
  value       = module.networking.private_route_table_ids
}

output "database_route_table_ids" {
  description = "IDs of database route tables"
  value       = module.networking.database_route_table_ids
}

# Network Security
output "public_network_acl_id" {
  description = "ID of the public network ACL"
  value       = module.networking.public_network_acl_id
}

output "private_network_acl_id" {
  description = "ID of the private network ACL"
  value       = module.networking.private_network_acl_id
}

output "database_network_acl_id" {
  description = "ID of the database network ACL"
  value       = module.networking.database_network_acl_id
}

# Monitoring
output "vpc_flow_logs_log_group_name" {
  description = "Name of VPC Flow Logs CloudWatch log group"
  value       = module.networking.vpc_flow_logs_log_group_name
}

output "vpc_flow_logs_iam_role_arn" {
  description = "ARN of VPC Flow Logs IAM role"
  value       = module.networking.vpc_flow_logs_iam_role_arn
}

# Environment Information
output "environment" {
  description = "Environment name"
  value       = "production"
}

output "region" {
  description = "AWS region"
  value       = var.aws_region
}

# Resource Naming
output "name_prefix" {
  description = "Name prefix used for all resources"
  value       = module.networking.name_prefix
}

# Tags
output "common_tags" {
  description = "Common tags applied to all resources"
  value       = module.networking.common_tags
}