# ElastiCache Module Outputs

output "replication_group_id" {
  description = "ElastiCache replication group ID"
  value       = aws_elasticache_replication_group.main.id
}

output "replication_group_arn" {
  description = "ElastiCache replication group ARN"
  value       = aws_elasticache_replication_group.main.arn
}

output "primary_endpoint_address" {
  description = "Primary endpoint address"
  value       = aws_elasticache_replication_group.main.primary_endpoint_address
}

output "configuration_endpoint_address" {
  description = "Configuration endpoint address (for cluster mode)"
  value       = aws_elasticache_replication_group.main.configuration_endpoint_address
}

output "reader_endpoint_address" {
  description = "Reader endpoint address"
  value       = aws_elasticache_replication_group.main.reader_endpoint_address
}

output "port" {
  description = "Redis port"
  value       = var.port
}

output "engine_version" {
  description = "Redis engine version"
  value       = aws_elasticache_replication_group.main.engine_version
}

output "node_type" {
  description = "Node type"
  value       = aws_elasticache_replication_group.main.node_type
}

output "num_cache_clusters" {
  description = "Number of cache clusters"
  value       = aws_elasticache_replication_group.main.num_cache_clusters
}

output "member_clusters" {
  description = "List of member cluster IDs"
  value       = aws_elasticache_replication_group.main.member_clusters
}

output "subnet_group_name" {
  description = "ElastiCache subnet group name"
  value       = aws_elasticache_subnet_group.main.name
}

output "parameter_group_name" {
  description = "ElastiCache parameter group name"
  value       = aws_elasticache_parameter_group.main.name
}

output "secrets_manager_secret_arn" {
  description = "ARN of Secrets Manager secret containing Redis auth token"
  value       = aws_secretsmanager_secret.redis_auth.arn
}

output "secrets_manager_secret_name" {
  description = "Name of Secrets Manager secret containing Redis auth token"
  value       = aws_secretsmanager_secret.redis_auth.name
}

output "cloudwatch_log_group_name" {
  description = "CloudWatch log group name for Redis slow logs"
  value       = aws_cloudwatch_log_group.redis_slow.name
}

output "global_replication_group_id" {
  description = "Global replication group ID"
  value       = var.create_global_replication_group ? aws_elasticache_global_replication_group.main[0].global_replication_group_id : null
}

output "app_user_id" {
  description = "Application user ID"
  value       = var.create_app_user ? aws_elasticache_user.app_user[0].user_id : null
}

output "user_group_id" {
  description = "User group ID"
  value       = var.create_app_user ? aws_elasticache_user_group.main[0].user_group_id : null
}

# Connection string outputs for applications
output "redis_url" {
  description = "Redis connection URL with auth token"
  value       = "rediss://:${urlencode(random_password.auth_token.result)}@${aws_elasticache_replication_group.main.primary_endpoint_address != null ? aws_elasticache_replication_group.main.primary_endpoint_address : aws_elasticache_replication_group.main.configuration_endpoint_address}:${var.port}"
  sensitive   = true
}

output "redis_url_without_password" {
  description = "Redis connection URL without auth token"
  value       = "rediss://<auth_token>@${aws_elasticache_replication_group.main.primary_endpoint_address != null ? aws_elasticache_replication_group.main.primary_endpoint_address : aws_elasticache_replication_group.main.configuration_endpoint_address}:${var.port}"
}

output "connection_info" {
  description = "Connection information for Redis cluster"
  value = {
    host       = aws_elasticache_replication_group.main.primary_endpoint_address != null ? aws_elasticache_replication_group.main.primary_endpoint_address : aws_elasticache_replication_group.main.configuration_endpoint_address
    port       = var.port
    ssl        = true
    auth_token_secret = aws_secretsmanager_secret.redis_auth.name
  }
}