# Storage Module Outputs

# PostgreSQL Outputs
output "postgresql_instance_id" {
  description = "PostgreSQL RDS instance ID"
  value       = aws_db_instance.postgresql.id
}

output "postgresql_instance_arn" {
  description = "PostgreSQL RDS instance ARN"
  value       = aws_db_instance.postgresql.arn
}

output "postgresql_endpoint" {
  description = "PostgreSQL endpoint"
  value       = aws_db_instance.postgresql.endpoint
}

output "postgresql_port" {
  description = "PostgreSQL port"
  value       = aws_db_instance.postgresql.port
}

output "postgresql_database_name" {
  description = "PostgreSQL database name"
  value       = aws_db_instance.postgresql.db_name
}

output "postgresql_master_username" {
  description = "PostgreSQL master username"
  value       = aws_db_instance.postgresql.username
  sensitive   = true
}

output "postgresql_credentials_secret_arn" {
  description = "ARN of the Secrets Manager secret containing PostgreSQL credentials"
  value       = aws_secretsmanager_secret.postgresql_credentials.arn
}

output "postgresql_credentials_secret_name" {
  description = "Name of the Secrets Manager secret containing PostgreSQL credentials"
  value       = aws_secretsmanager_secret.postgresql_credentials.name
}

output "postgresql_read_replica_endpoint" {
  description = "PostgreSQL read replica endpoint"
  value       = var.create_read_replica ? aws_db_instance.postgresql_read_replica[0].endpoint : null
}

output "postgresql_kms_key_id" {
  description = "KMS key ID used for PostgreSQL encryption"
  value       = var.enable_encryption ? aws_kms_key.postgresql[0].id : null
}

output "postgresql_kms_key_arn" {
  description = "KMS key ARN used for PostgreSQL encryption"
  value       = var.enable_encryption ? aws_kms_key.postgresql[0].arn : null
}

# Redis Outputs
output "redis_replication_group_id" {
  description = "Redis replication group ID"
  value       = aws_elasticache_replication_group.redis.id
}

output "redis_replication_group_arn" {
  description = "Redis replication group ARN"
  value       = aws_elasticache_replication_group.redis.arn
}

output "redis_primary_endpoint_address" {
  description = "Redis primary endpoint address"
  value       = aws_elasticache_replication_group.redis.primary_endpoint_address
}

output "redis_reader_endpoint_address" {
  description = "Redis reader endpoint address"
  value       = aws_elasticache_replication_group.redis.reader_endpoint_address
}

output "redis_port" {
  description = "Redis port"
  value       = aws_elasticache_replication_group.redis.port
}

output "redis_auth_token_secret_arn" {
  description = "ARN of the Secrets Manager secret containing Redis auth token"
  value       = var.enable_encryption ? aws_secretsmanager_secret.redis_auth_token[0].arn : null
}

output "redis_auth_token_secret_name" {
  description = "Name of the Secrets Manager secret containing Redis auth token"
  value       = var.enable_encryption ? aws_secretsmanager_secret.redis_auth_token[0].name : null
}

output "redis_sessions_replication_group_id" {
  description = "Redis sessions replication group ID"
  value       = var.create_session_store ? aws_elasticache_replication_group.redis_sessions[0].id : null
}

output "redis_sessions_primary_endpoint_address" {
  description = "Redis sessions primary endpoint address"
  value       = var.create_session_store ? aws_elasticache_replication_group.redis_sessions[0].primary_endpoint_address : null
}

output "redis_sessions_auth_token_secret_arn" {
  description = "ARN of the Secrets Manager secret containing Redis sessions auth token"
  value       = var.create_session_store && var.enable_encryption ? aws_secretsmanager_secret.redis_sessions_auth_token[0].arn : null
}

output "elasticache_kms_key_id" {
  description = "KMS key ID used for ElastiCache encryption"
  value       = var.enable_encryption ? aws_kms_key.elasticache[0].id : null
}

output "elasticache_kms_key_arn" {
  description = "KMS key ARN used for ElastiCache encryption"
  value       = var.enable_encryption ? aws_kms_key.elasticache[0].arn : null
}

# Subnet Group Outputs
output "elasticache_subnet_group_name" {
  description = "ElastiCache subnet group name"
  value       = aws_elasticache_subnet_group.redis.name
}

# Parameter Group Outputs
output "postgresql_parameter_group_name" {
  description = "PostgreSQL parameter group name"
  value       = aws_db_parameter_group.postgresql.name
}

output "redis_parameter_group_name" {
  description = "Redis parameter group name"
  value       = aws_elasticache_parameter_group.redis.name
}

# Monitoring Outputs
output "postgresql_cloudwatch_log_groups" {
  description = "PostgreSQL CloudWatch log groups"
  value       = { for k, v in aws_cloudwatch_log_group.postgresql_logs : k => v.name }
}

output "redis_cloudwatch_log_group" {
  description = "Redis CloudWatch log group"
  value       = var.enable_redis_logging ? aws_cloudwatch_log_group.redis_slow_log[0].name : null
}