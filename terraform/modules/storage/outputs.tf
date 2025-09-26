output "redis_cluster_id" {
  description = "ElastiCache Redis replication group ID"
  value       = aws_elasticache_replication_group.redis.replication_group_id
}

output "redis_endpoint" {
  description = "ElastiCache Redis primary endpoint"
  value       = aws_elasticache_replication_group.redis.configuration_endpoint_address != null ? aws_elasticache_replication_group.redis.configuration_endpoint_address : aws_elasticache_replication_group.redis.primary_endpoint_address
}

output "redis_port" {
  description = "ElastiCache Redis cluster port"
  value       = aws_elasticache_replication_group.redis.port
}

output "redis_security_group_id" {
  description = "Security group ID for Redis cluster"
  value       = aws_security_group.redis.id
}

# Redis AUTH token for Vault synchronization
# This output allows the token to be retrieved and stored in Vault
output "redis_auth_token" {
  description = "Redis AUTH token for synchronization with Vault"
  value       = random_password.redis_auth_token.result
  sensitive   = true
}

# Redis AUTH tokens are now stored in HashiCorp Vault
# Access via Vault Secrets Operator in Kubernetes
# output "redis_auth_token_secret_arn" - deprecated in favor of Vault

# Redis AUTH tokens are now stored in HashiCorp Vault
# Access via Vault path: {environment}/redis/auth-token
# output "redis_auth_token_secret_name" - deprecated in favor of Vault

output "redis_subnet_group_name" {
  description = "ElastiCache subnet group name"
  value       = aws_elasticache_subnet_group.redis.name
}

output "redis_parameter_group_name" {
  description = "ElastiCache parameter group name"
  value       = aws_elasticache_parameter_group.redis.name
}

output "redis_log_group_name" {
  description = "CloudWatch log group name for Redis slow log"
  value       = aws_cloudwatch_log_group.redis_slow_log.name
}