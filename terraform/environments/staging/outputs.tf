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

# Monitoring Outputs
output "vpc_flow_logs_s3_bucket_name" {
  description = "Name of the staging VPC Flow Logs S3 bucket"
  value       = module.monitoring.vpc_flow_logs_s3_bucket_name
}