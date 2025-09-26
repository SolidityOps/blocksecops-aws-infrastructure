# Redis AUTH token for initial ElastiCache setup
# This token will be stored in Vault and managed there
# The token should match what's stored in Vault at: {environment}/redis/auth-token
resource "random_password" "redis_auth_token" {
  length  = var.auth_token_length
  special = true

  # Keep this token stable unless explicitly changed
  keepers = {
    environment = var.environment
  }
}

# Redis AUTH token is now managed by HashiCorp Vault
# The token is stored in Vault at: {environment}/redis/auth-token
# This removes dependency on AWS Secrets Manager

# Redis connection details are now managed by HashiCorp Vault
# Applications access Redis credentials via Vault Secrets Operator
# Example Vault path: {environment}/redis/auth-token

resource "aws_elasticache_subnet_group" "redis" {
  name       = "${var.environment}-redis-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = merge(var.tags, {
    Name        = "${var.environment}-redis-subnet-group"
    Component   = "cache"
    Environment = var.environment
  })
}

resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "${var.environment}-redis"
  engine               = "redis"
  node_type            = var.redis_node_type
  num_cache_nodes      = var.redis_num_cache_nodes
  parameter_group_name = aws_elasticache_parameter_group.redis.name
  port                 = var.redis_port
  subnet_group_name    = aws_elasticache_subnet_group.redis.name
  security_group_ids   = [aws_security_group.redis.id]
  engine_version       = var.redis_engine_version

  # Security configurations
  # Note: AUTH token and encryption are only available with replication groups
  # For single-node clusters in staging, access is controlled via security groups
  # Production should use aws_elasticache_replication_group for full encryption support

  # Backup configurations
  snapshot_retention_limit = var.backup_retention_limit
  snapshot_window          = var.snapshot_window
  maintenance_window       = var.maintenance_window

  # Logging configuration
  log_delivery_configuration {
    destination      = aws_cloudwatch_log_group.redis_slow_log.name
    destination_type = "cloudwatch-logs"
    log_format       = "text"
    log_type         = "slow-log"
  }

  tags = merge(var.tags, {
    Name        = "${var.environment}-redis-cluster"
    Component   = "cache"
    Environment = var.environment
  })

  depends_on = [
    aws_elasticache_parameter_group.redis,
    aws_elasticache_subnet_group.redis,
    aws_security_group.redis
  ]
}

resource "aws_cloudwatch_log_group" "redis_slow_log" {
  name              = "/aws/elasticache/${var.environment}-redis/slow-log"
  retention_in_days = var.environment == "production" ? 90 : 7

  tags = merge(var.tags, {
    Name        = "${var.environment}-redis-slow-log"
    Component   = "cache"
    Environment = var.environment
  })
}