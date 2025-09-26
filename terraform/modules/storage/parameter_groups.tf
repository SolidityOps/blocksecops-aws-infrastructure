resource "aws_elasticache_parameter_group" "redis" {
  family = var.redis_parameter_group_family
  name   = "${var.environment}-redis-params"

  parameter {
    name  = "maxmemory-policy"
    value = "allkeys-lru"
  }

  parameter {
    name  = "timeout"
    value = "300"
  }

  parameter {
    name  = "tcp-keepalive"
    value = "300"
  }

  parameter {
    name  = "maxclients"
    value = "10000"
  }

  tags = merge(var.tags, {
    Name        = "${var.environment}-redis-parameter-group"
    Component   = "cache"
    Environment = var.environment
  })
}