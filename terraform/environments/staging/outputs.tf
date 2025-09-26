# Outputs for Staging Environment

# VPC Outputs
output "vpc_id" {
  description = "ID of the staging VPC"
  value       = module.networking.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the staging VPC"
  value       = module.networking.vpc_cidr_block
}

# Subnet Outputs
output "public_subnet_id" {
  description = "ID of the staging public subnet"
  value       = module.networking.public_subnet_id
}

output "private_subnet_id" {
  description = "ID of the staging private subnet"
  value       = module.networking.private_subnet_id
}

output "availability_zone" {
  description = "Availability zone used for staging subnets"
  value       = module.networking.availability_zone
}

# Security Group Outputs
output "eks_cluster_security_group_id" {
  description = "ID of the staging EKS cluster security group"
  value       = module.networking.eks_cluster_security_group_id
}

output "eks_nodes_security_group_id" {
  description = "ID of the staging EKS nodes security group"
  value       = module.networking.eks_nodes_security_group_id
}

output "alb_security_group_id" {
  description = "ID of the staging ALB security group"
  value       = module.networking.alb_security_group_id
}

# PostgreSQL runs in Kubernetes with NetworkPolicies
# No RDS security group needed for staging

output "elasticache_security_group_id" {
  description = "ID of the staging ElastiCache security group"
  value       = module.networking.elasticache_security_group_id
}

# Network Infrastructure Outputs
output "nat_gateway_ip" {
  description = "Public IP of the staging NAT Gateway"
  value       = module.networking.nat_gateway_ip
}

output "internet_gateway_id" {
  description = "ID of the staging Internet Gateway"
  value       = module.networking.internet_gateway_id
}

# ElastiCache Redis Outputs
output "redis_cluster_id" {
  description = "ElastiCache Redis cluster ID for staging"
  value       = module.storage.redis_cluster_id
}

output "redis_endpoint" {
  description = "ElastiCache Redis cluster endpoint for staging"
  value       = module.storage.redis_endpoint
}

output "redis_port" {
  description = "ElastiCache Redis cluster port for staging"
  value       = module.storage.redis_port
}

output "redis_auth_token" {
  description = "Redis AUTH token for staging (for Vault synchronization)"
  value       = module.storage.redis_auth_token
  sensitive   = true
}

# Redis AUTH tokens are now stored in HashiCorp Vault
# Access via Vault Secrets Operator in Kubernetes
# output "redis_auth_token_secret_arn" - deprecated in favor of Vault

# Redis AUTH tokens are now stored in HashiCorp Vault
# Access via Vault path: staging/redis/auth-token
# output "redis_auth_token_secret_name" - deprecated in favor of Vault

# Cache Monitoring Outputs
output "redis_dashboard_url" {
  description = "URL of the Redis CloudWatch dashboard for staging"
  value       = module.cache_monitoring.redis_dashboard_url
}

# Monitoring Outputs
output "vpc_flow_logs_s3_bucket_name" {
  description = "Name of the staging VPC Flow Logs S3 bucket"
  value       = module.monitoring.vpc_flow_logs_s3_bucket_name
}