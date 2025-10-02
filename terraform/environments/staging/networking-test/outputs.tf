# Outputs for staging networking environment

# VPC Information
output "vpc_id" {
  description = "ID of the staging VPC"
  value       = module.networking.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the staging VPC"
  value       = module.networking.vpc_cidr_block
}

output "availability_zones" {
  description = "Availability zones used in staging"
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

# NAT Information
output "nat_gateway_ids" {
  description = "IDs of NAT gateways (if enabled)"
  value       = module.networking.nat_gateway_ids
}

output "nat_instance_ids" {
  description = "IDs of NAT instances (if using NAT instance)"
  value       = module.networking.nat_instance_ids
}

output "nat_public_ips" {
  description = "Public IPs of NAT resources"
  value       = module.networking.nat_public_ips
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

# Monitoring
output "vpc_flow_logs_log_group_name" {
  description = "Name of VPC Flow Logs CloudWatch log group"
  value       = module.networking.vpc_flow_logs_log_group_name
}

# Environment Information
output "environment" {
  description = "Environment name"
  value       = "staging"
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