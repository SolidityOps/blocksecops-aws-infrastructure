resource "random_password" "redis_auth_token" {
  length  = var.auth_token_length
  special = true
}

resource "aws_secretsmanager_secret" "redis_auth_token" {
  name        = "${var.environment}-redis-auth-token"
  description = "Redis AUTH token for ${var.environment} environment"

  tags = merge(var.tags, {
    Name        = "${var.environment}-redis-auth-token"
    Component   = "cache"
    Environment = var.environment
  })
}

resource "aws_secretsmanager_secret_version" "redis_auth_token" {
  secret_id = aws_secretsmanager_secret.redis_auth_token.id
  secret_string = jsonencode({
    auth_token = random_password.redis_auth_token.result
    host       = aws_elasticache_cluster.redis.cache_nodes[0].address
    port       = var.redis_port
  })
}

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
  auth_token                 = random_password.redis_auth_token.result
  transit_encryption_enabled = true
  at_rest_encryption_enabled = true

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