# Outputs for networking module

# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "vpc_arn" {
  description = "ARN of the VPC"
  value       = aws_vpc.main.arn
}

# Internet Gateway Outputs
output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

# Availability Zone Outputs
output "availability_zones" {
  description = "List of availability zones used"
  value       = local.selected_azs
}

# Subnet Outputs
output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "database_subnet_ids" {
  description = "IDs of the database subnets"
  value       = var.create_database_subnets ? aws_subnet.database[*].id : []
}

output "public_subnet_cidr_blocks" {
  description = "CIDR blocks of the public subnets"
  value       = aws_subnet.public[*].cidr_block
}

output "private_subnet_cidr_blocks" {
  description = "CIDR blocks of the private subnets"
  value       = aws_subnet.private[*].cidr_block
}

output "database_subnet_cidr_blocks" {
  description = "CIDR blocks of the database subnets"
  value       = var.create_database_subnets ? aws_subnet.database[*].cidr_block : []
}

# Subnet Group Outputs
output "db_subnet_group_name" {
  description = "Name of the database subnet group"
  value       = var.create_database_subnets ? aws_db_subnet_group.main[0].name : null
}

output "elasticache_subnet_group_name" {
  description = "Name of the ElastiCache subnet group"
  value       = var.create_database_subnets ? aws_elasticache_subnet_group.main[0].name : null
}

# NAT Gateway Outputs
output "nat_gateway_ids" {
  description = "IDs of the NAT gateways"
  value       = var.enable_nat_gateway ? aws_nat_gateway.main[*].id : []
}

output "nat_instance_ids" {
  description = "IDs of the NAT instances"
  value       = var.use_nat_instance && !var.enable_nat_gateway ? aws_instance.nat[*].id : []
}

output "nat_public_ips" {
  description = "Public IP addresses of NAT gateways/instances"
  value = var.enable_nat_gateway ? aws_eip.nat[*].public_ip : (
    var.use_nat_instance && !var.enable_nat_gateway ? aws_instance.nat[*].public_ip : []
  )
}

# Route Table Outputs
output "public_route_table_ids" {
  description = "IDs of the public route tables"
  value       = aws_route_table.public[*].id
}

output "private_route_table_ids" {
  description = "IDs of the private route tables"
  value       = aws_route_table.private[*].id
}

output "database_route_table_ids" {
  description = "IDs of the database route tables"
  value       = var.create_database_subnets ? aws_route_table.database[*].id : []
}

# Security Group Outputs
output "eks_cluster_security_group_id" {
  description = "ID of the EKS cluster security group"
  value       = var.create_eks_security_groups ? aws_security_group.eks_cluster[0].id : null
}

output "eks_nodes_security_group_id" {
  description = "ID of the EKS nodes security group"
  value       = var.create_eks_security_groups ? aws_security_group.eks_nodes[0].id : null
}

output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = var.create_alb_security_group ? aws_security_group.alb[0].id : null
}

output "postgresql_security_group_id" {
  description = "ID of the PostgreSQL security group"
  value       = var.create_database_security_groups ? aws_security_group.postgresql[0].id : null
}

output "elasticache_security_group_id" {
  description = "ID of the ElastiCache security group"
  value       = var.create_database_security_groups ? aws_security_group.elasticache[0].id : null
}

output "vpc_endpoints_security_group_id" {
  description = "ID of the VPC endpoints security group"
  value       = var.create_vpc_endpoints ? aws_security_group.vpc_endpoints[0].id : null
}

output "bastion_security_group_id" {
  description = "ID of the bastion security group"
  value       = var.create_bastion_security_group ? aws_security_group.bastion[0].id : null
}

# VPC Endpoint Outputs
output "vpc_endpoint_s3_id" {
  description = "ID of the S3 VPC endpoint"
  value       = var.create_vpc_endpoints ? aws_vpc_endpoint.s3[0].id : null
}

output "vpc_endpoint_dynamodb_id" {
  description = "ID of the DynamoDB VPC endpoint"
  value       = var.create_vpc_endpoints ? aws_vpc_endpoint.dynamodb[0].id : null
}

output "vpc_endpoint_ecr_api_id" {
  description = "ID of the ECR API VPC endpoint"
  value       = var.create_vpc_endpoints ? aws_vpc_endpoint.ecr_api[0].id : null
}

output "vpc_endpoint_ecr_dkr_id" {
  description = "ID of the ECR DKR VPC endpoint"
  value       = var.create_vpc_endpoints ? aws_vpc_endpoint.ecr_dkr[0].id : null
}

output "vpc_endpoint_secrets_manager_id" {
  description = "ID of the Secrets Manager VPC endpoint"
  value       = var.create_vpc_endpoints ? aws_vpc_endpoint.secrets_manager[0].id : null
}

# Network ACL Outputs
output "public_network_acl_id" {
  description = "ID of the public network ACL"
  value       = var.create_network_acls ? aws_network_acl.public[0].id : null
}

output "private_network_acl_id" {
  description = "ID of the private network ACL"
  value       = var.create_network_acls ? aws_network_acl.private[0].id : null
}

output "database_network_acl_id" {
  description = "ID of the database network ACL"
  value       = var.create_network_acls && var.create_database_subnets ? aws_network_acl.database[0].id : null
}

# VPC Flow Logs Outputs
output "vpc_flow_logs_log_group_name" {
  description = "Name of the VPC Flow Logs CloudWatch log group"
  value       = var.enable_vpc_flow_logs ? aws_cloudwatch_log_group.vpc_flow_logs[0].name : null
}

output "vpc_flow_logs_iam_role_arn" {
  description = "ARN of the VPC Flow Logs IAM role"
  value       = var.enable_vpc_flow_logs ? aws_iam_role.flow_logs[0].arn : null
}

# Resource Name Prefix
output "name_prefix" {
  description = "Name prefix used for all resources"
  value       = local.name_prefix
}

# Common Tags
output "common_tags" {
  description = "Common tags applied to all resources"
  value       = local.common_tags
}