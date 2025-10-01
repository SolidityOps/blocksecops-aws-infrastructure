# Production Storage Environment Outputs

# PostgreSQL Outputs
output "postgresql_instance_id" {
  description = "PostgreSQL RDS instance ID"
  value       = module.storage.postgresql_instance_id
}

output "postgresql_endpoint" {
  description = "PostgreSQL endpoint"
  value       = module.storage.postgresql_endpoint
}

output "postgresql_read_replica_endpoint" {
  description = "PostgreSQL read replica endpoint"
  value       = module.storage.postgresql_read_replica_endpoint
}

output "postgresql_port" {
  description = "PostgreSQL port"
  value       = module.storage.postgresql_port
}

output "postgresql_database_name" {
  description = "PostgreSQL database name"
  value       = module.storage.postgresql_database_name
}

output "postgresql_credentials_secret_arn" {
  description = "ARN of the Secrets Manager secret containing PostgreSQL credentials"
  value       = module.storage.postgresql_credentials_secret_arn
}

output "postgresql_credentials_secret_name" {
  description = "Name of the Secrets Manager secret containing PostgreSQL credentials"
  value       = module.storage.postgresql_credentials_secret_name
}

# Redis Outputs
output "redis_replication_group_id" {
  description = "Redis replication group ID"
  value       = module.storage.redis_replication_group_id
}

output "redis_primary_endpoint_address" {
  description = "Redis primary endpoint address"
  value       = module.storage.redis_primary_endpoint_address
}

output "redis_reader_endpoint_address" {
  description = "Redis reader endpoint address"
  value       = module.storage.redis_reader_endpoint_address
}

output "redis_port" {
  description = "Redis port"
  value       = module.storage.redis_port
}

output "redis_auth_token_secret_arn" {
  description = "ARN of the Secrets Manager secret containing Redis auth token"
  value       = module.storage.redis_auth_token_secret_arn
}

output "redis_auth_token_secret_name" {
  description = "Name of the Secrets Manager secret containing Redis auth token"
  value       = module.storage.redis_auth_token_secret_name
}

# Session Store Outputs
output "redis_sessions_replication_group_id" {
  description = "Redis sessions replication group ID"
  value       = module.storage.redis_sessions_replication_group_id
}

output "redis_sessions_primary_endpoint_address" {
  description = "Redis sessions primary endpoint address"
  value       = module.storage.redis_sessions_primary_endpoint_address
}

output "redis_sessions_auth_token_secret_arn" {
  description = "ARN of the Secrets Manager secret containing Redis sessions auth token"
  value       = module.storage.redis_sessions_auth_token_secret_arn
}

# Connection Information for Applications
output "database_connection_info" {
  description = "Database connection information for applications"
  value = {
    postgresql = {
      primary_endpoint       = module.storage.postgresql_endpoint
      read_replica_endpoint  = module.storage.postgresql_read_replica_endpoint
      port                   = module.storage.postgresql_port
      database_name          = module.storage.postgresql_database_name
      credentials_secret_arn = module.storage.postgresql_credentials_secret_arn
    }
    redis = {
      primary_endpoint      = module.storage.redis_primary_endpoint_address
      reader_endpoint       = module.storage.redis_reader_endpoint_address
      port                  = module.storage.redis_port
      auth_token_secret_arn = module.storage.redis_auth_token_secret_arn
    }
    redis_sessions = {
      primary_endpoint      = module.storage.redis_sessions_primary_endpoint_address
      port                  = module.storage.redis_port
      auth_token_secret_arn = module.storage.redis_sessions_auth_token_secret_arn
    }
  }
  sensitive = true
}

# High Availability Status
output "high_availability_status" {
  description = "High availability configuration status"
  value = {
    postgresql_multi_az              = true
    postgresql_read_replica_enabled  = true
    redis_multi_az_enabled           = true
    redis_automatic_failover_enabled = true
    session_store_enabled            = true
  }
}