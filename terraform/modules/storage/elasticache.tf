# ElastiCache Redis Configuration

# ElastiCache subnet group
resource "aws_elasticache_subnet_group" "redis" {
  name       = "${local.name_prefix}-redis-subnet-group"
  subnet_ids = var.elasticache_subnet_ids

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-redis-subnet-group"
    Type = "elasticache-subnet-group"
  })
}

# ElastiCache parameter group
resource "aws_elasticache_parameter_group" "redis" {
  family = "redis${split(".", var.redis_engine_version)[0]}"
  name   = "${local.name_prefix}-redis-params"

  description = "Redis parameter group for ${var.environment}"

  # Redis configuration parameters
  dynamic "parameter" {
    for_each = var.redis_parameters
    content {
      name  = parameter.value.name
      value = parameter.value.value
    }
  }

  # Default Redis parameters for application workloads
  parameter {
    name  = "maxmemory-policy"
    value = "allkeys-lru"
  }

  parameter {
    name  = "timeout"
    value = "300"
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-redis-params"
    Type = "parameter-group"
  })
}

# KMS key for ElastiCache encryption
resource "aws_kms_key" "elasticache" {
  count = var.enable_encryption ? 1 : 0

  description             = "KMS key for ElastiCache Redis encryption"
  deletion_window_in_days = var.environment == "production" ? 30 : 7

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-elasticache-kms"
    Type = "encryption-key"
  })
}

resource "aws_kms_alias" "elasticache" {
  count = var.enable_encryption ? 1 : 0

  name          = "alias/${local.name_prefix}-elasticache"
  target_key_id = aws_kms_key.elasticache[0].key_id
}

# ElastiCache Redis Replication Group
resource "aws_elasticache_replication_group" "redis" {
  replication_group_id = "${local.name_prefix}-redis"
  description          = "Redis cluster for ${var.environment} environment"

  # Engine configuration
  engine         = "redis"
  engine_version = var.redis_engine_version
  node_type      = var.redis_node_type
  port           = var.redis_port

  # Cluster configuration
  num_cache_clusters = var.redis_num_cache_clusters

  # Parameter group
  parameter_group_name = aws_elasticache_parameter_group.redis.name

  # Network configuration
  subnet_group_name  = aws_elasticache_subnet_group.redis.name
  security_group_ids = var.redis_security_group_ids

  # Security configuration
  at_rest_encryption_enabled = var.enable_encryption
  transit_encryption_enabled = var.enable_encryption
  auth_token                 = var.enable_encryption ? random_password.redis_auth_token[0].result : null
  kms_key_id                 = var.enable_encryption ? aws_kms_key.elasticache[0].arn : null

  # Backup configuration
  automatic_failover_enabled = var.redis_automatic_failover_enabled
  multi_az_enabled           = var.redis_multi_az_enabled
  snapshot_retention_limit   = var.redis_snapshot_retention_limit
  snapshot_window            = var.redis_snapshot_window

  # Maintenance
  maintenance_window         = var.redis_maintenance_window
  auto_minor_version_upgrade = var.redis_auto_minor_version_upgrade

  # Logging
  dynamic "log_delivery_configuration" {
    for_each = var.enable_redis_logging ? [1] : []
    content {
      destination      = aws_cloudwatch_log_group.redis_slow_log[0].name
      destination_type = "cloudwatch-logs"
      log_format       = "text"
      log_type         = "slow-log"
    }
  }

  tags = merge(local.common_tags, {
    Name   = "${local.name_prefix}-redis"
    Type   = "elasticache-replication-group"
    Engine = "redis"
  })

  depends_on = var.enable_redis_logging ? [aws_cloudwatch_log_group.redis_slow_log] : []
}

# Random auth token for Redis
resource "random_password" "redis_auth_token" {
  count = var.enable_encryption ? 1 : 0

  length  = 32
  special = false # Redis auth token cannot contain special characters
}

# AWS Secrets Manager secret for Redis auth token
resource "aws_secretsmanager_secret" "redis_auth_token" {
  count = var.enable_encryption ? 1 : 0

  name                    = "${local.name_prefix}-redis-auth-token"
  description             = "Redis auth token for ${var.environment}"
  recovery_window_in_days = var.environment == "production" ? 30 : 0

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-redis-auth-token"
    Type = "cache-credentials"
  })
}

resource "aws_secretsmanager_secret_version" "redis_auth_token" {
  count = var.enable_encryption ? 1 : 0

  secret_id = aws_secretsmanager_secret.redis_auth_token[0].id
  secret_string = jsonencode({
    auth_token = random_password.redis_auth_token[0].result
    engine     = "redis"
    host       = aws_elasticache_replication_group.redis.primary_endpoint_address
    port       = aws_elasticache_replication_group.redis.port
  })
}

# CloudWatch Log Groups for Redis logs
resource "aws_cloudwatch_log_group" "redis_slow_log" {
  count = var.enable_redis_logging ? 1 : 0

  name              = "/aws/elasticache/redis/${local.name_prefix}/slow-log"
  retention_in_days = var.log_retention_days

  tags = merge(local.common_tags, {
    Name    = "${local.name_prefix}-redis-slow-log"
    Type    = "cache-logs"
    Cache   = "redis"
    LogType = "slow-log"
  })
}

# ElastiCache Redis Cluster for session storage (optional)
resource "aws_elasticache_replication_group" "redis_sessions" {
  count = var.create_session_store ? 1 : 0

  replication_group_id = "${local.name_prefix}-redis-sessions"
  description          = "Redis cluster for session storage in ${var.environment}"

  # Engine configuration
  engine         = "redis"
  engine_version = var.redis_engine_version
  node_type      = var.redis_session_node_type
  port           = var.redis_port

  # Cluster configuration
  num_cache_clusters = var.redis_session_num_cache_clusters

  # Parameter group
  parameter_group_name = aws_elasticache_parameter_group.redis.name

  # Network configuration
  subnet_group_name  = aws_elasticache_subnet_group.redis.name
  security_group_ids = var.redis_security_group_ids

  # Security configuration
  at_rest_encryption_enabled = var.enable_encryption
  transit_encryption_enabled = var.enable_encryption
  auth_token                 = var.enable_encryption ? random_password.redis_sessions_auth_token[0].result : null
  kms_key_id                 = var.enable_encryption ? aws_kms_key.elasticache[0].arn : null

  # Backup configuration - minimal for session store
  automatic_failover_enabled = false
  multi_az_enabled           = false
  snapshot_retention_limit   = 1
  snapshot_window            = var.redis_snapshot_window

  # Maintenance
  maintenance_window         = var.redis_maintenance_window
  auto_minor_version_upgrade = var.redis_auto_minor_version_upgrade

  tags = merge(local.common_tags, {
    Name    = "${local.name_prefix}-redis-sessions"
    Type    = "elasticache-session-store"
    Engine  = "redis"
    Purpose = "session-storage"
  })
}

# Random auth token for Redis sessions
resource "random_password" "redis_sessions_auth_token" {
  count = var.create_session_store && var.enable_encryption ? 1 : 0

  length  = 32
  special = false
}

# AWS Secrets Manager secret for Redis sessions auth token
resource "aws_secretsmanager_secret" "redis_sessions_auth_token" {
  count = var.create_session_store && var.enable_encryption ? 1 : 0

  name                    = "${local.name_prefix}-redis-sessions-auth-token"
  description             = "Redis sessions auth token for ${var.environment}"
  recovery_window_in_days = var.environment == "production" ? 30 : 0

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-redis-sessions-auth-token"
    Type = "session-store-credentials"
  })
}

resource "aws_secretsmanager_secret_version" "redis_sessions_auth_token" {
  count = var.create_session_store && var.enable_encryption ? 1 : 0

  secret_id = aws_secretsmanager_secret.redis_sessions_auth_token[0].id
  secret_string = jsonencode({
    auth_token = random_password.redis_sessions_auth_token[0].result
    engine     = "redis"
    host       = aws_elasticache_replication_group.redis_sessions[0].primary_endpoint_address
    port       = aws_elasticache_replication_group.redis_sessions[0].port
  })
}