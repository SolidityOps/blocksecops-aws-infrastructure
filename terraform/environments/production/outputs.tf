# Outputs for Production Environment

# VPC Outputs
output "vpc_id" {
  description = "ID of the production VPC"
  value       = module.networking.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the production VPC"
  value       = module.networking.vpc_cidr_block
}

# Subnet Outputs
output "public_subnet_id" {
  description = "ID of the production public subnet"
  value       = module.networking.public_subnet_id
}

output "private_subnet_id" {
  description = "ID of the production private subnet"
  value       = module.networking.private_subnet_id
}

output "availability_zone" {
  description = "Availability zone used for production subnets"
  value       = module.networking.availability_zone
}

# Security Group Outputs
output "eks_cluster_security_group_id" {
  description = "ID of the production EKS cluster security group"
  value       = module.networking.eks_cluster_security_group_id
}

output "eks_nodes_security_group_id" {
  description = "ID of the production EKS nodes security group"
  value       = module.networking.eks_nodes_security_group_id
}

output "alb_security_group_id" {
  description = "ID of the production ALB security group"
  value       = module.networking.alb_security_group_id
}

output "rds_security_group_id" {
  description = "ID of the production RDS security group"
  value       = module.networking.rds_security_group_id
}

output "elasticache_security_group_id" {
  description = "ID of the production ElastiCache security group"
  value       = module.networking.elasticache_security_group_id
}

# Network Infrastructure Outputs
output "nat_gateway_ip" {
  description = "Public IP of the production NAT Gateway"
  value       = module.networking.nat_gateway_ip
}

output "internet_gateway_id" {
  description = "ID of the production Internet Gateway"
  value       = module.networking.internet_gateway_id
}

# Monitoring Outputs
output "vpc_flow_logs_log_group_name" {
  description = "Name of the production VPC Flow Logs CloudWatch log group"
  value       = module.monitoring.vpc_flow_logs_log_group_name
}