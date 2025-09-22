# ElastiCache Module - Creates Redis cluster with cluster mode and parameter groups

# ElastiCache Subnet Group
resource "aws_elasticache_subnet_group" "main" {
  name       = "${var.project_name}-${var.environment}-cache-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name = "${var.project_name}-${var.environment}-cache-subnet-group"
  }
}

# ElastiCache Parameter Group
resource "aws_elasticache_parameter_group" "main" {
  family = var.parameter_group_family
  name   = "${var.project_name}-${var.environment}-redis-params"

  # Security parameters
  parameter {
    name  = "timeout"
    value = "300"
  }

  parameter {
    name  = "tcp-keepalive"
    value = "60"
  }

  parameter {
    name  = "maxmemory-policy"
    value = var.maxmemory_policy
  }

  parameter {
    name  = "notify-keyspace-events"
    value = "Ex"
  }

  parameter {
    name  = "slowlog-log-slower-than"
    value = "10000"
  }

  parameter {
    name  = "slowlog-max-len"
    value = "128"
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-redis-params"
  }
}

# Generate auth token for Redis
resource "random_password" "auth_token" {
  length  = 64
  special = false # Redis auth tokens cannot contain special characters
}

# ElastiCache Replication Group (Redis Cluster)
resource "aws_elasticache_replication_group" "main" {
  replication_group_id         = "${var.project_name}-${var.environment}-redis"
  description                  = "Redis cluster for ${var.project_name} ${var.environment}"

  # Engine configuration
  engine               = "redis"
  engine_version       = var.redis_version
  node_type           = var.node_type
  port                = var.port

  # Cluster configuration
  num_cache_clusters         = var.num_cache_clusters
  parameter_group_name       = aws_elasticache_parameter_group.main.name
  subnet_group_name          = aws_elasticache_subnet_group.main.name
  security_group_ids         = var.security_group_ids

  # Security
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  auth_token                 = random_password.auth_token.result
  kms_key_id                 = var.kms_key_arn

  # Maintenance
  maintenance_window         = var.maintenance_window
  notification_topic_arn     = var.notification_topic_arn

  # Backup
  snapshot_retention_limit = var.snapshot_retention_limit
  snapshot_window         = var.snapshot_window
  final_snapshot_identifier = var.final_snapshot_identifier

  # Logging
  log_delivery_configuration {
    destination      = aws_cloudwatch_log_group.redis_slow.name
    destination_type = "cloudwatch-logs"
    log_format       = "text"
    log_type         = "slow-log"
  }

  # Multi-AZ with automatic failover
  multi_az_enabled           = var.multi_az_enabled
  automatic_failover_enabled = var.automatic_failover_enabled

  # Auto minor version upgrade
  auto_minor_version_upgrade = var.auto_minor_version_upgrade

  tags = {
    Name = "${var.project_name}-${var.environment}-redis"
  }

  lifecycle {
    ignore_changes = [auth_token]
  }
}

# CloudWatch Log Group for Redis slow logs
resource "aws_cloudwatch_log_group" "redis_slow" {
  name              = "/aws/elasticache/${var.project_name}-${var.environment}/redis/slow-log"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn

  tags = {
    Name = "${var.project_name}-${var.environment}-redis-slow-log"
  }
}

# Store auth token in AWS Secrets Manager
resource "aws_secretsmanager_secret" "redis_auth" {
  name        = "${var.project_name}-${var.environment}/elasticache/auth-token"
  description = "Auth token for ${var.project_name} ${var.environment} Redis cluster"
  kms_key_id  = var.kms_key_arn

  tags = {
    Name = "${var.project_name}-${var.environment}-redis-auth"
  }
}

resource "aws_secretsmanager_secret_version" "redis_auth" {
  secret_id = aws_secretsmanager_secret.redis_auth.id
  secret_string = jsonencode({
    auth_token = random_password.auth_token.result
    host       = aws_elasticache_replication_group.main.primary_endpoint_address != null ? aws_elasticache_replication_group.main.primary_endpoint_address : aws_elasticache_replication_group.main.configuration_endpoint_address
    port       = var.port
    ssl        = true
    url        = "rediss://:${urlencode(random_password.auth_token.result)}@${aws_elasticache_replication_group.main.primary_endpoint_address != null ? aws_elasticache_replication_group.main.primary_endpoint_address : aws_elasticache_replication_group.main.configuration_endpoint_address}:${var.port}"
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}

# Optional: Global Datastore for cross-region replication
resource "aws_elasticache_global_replication_group" "main" {
  count = var.create_global_replication_group ? 1 : 0

  global_replication_group_id_suffix = "${var.project_name}-${var.environment}-global"
  primary_replication_group_id       = aws_elasticache_replication_group.main.id

  global_replication_group_description = "Global datastore for ${var.project_name} ${var.environment}"

  tags = {
    Name = "${var.project_name}-${var.environment}-redis-global"
  }
}

# ElastiCache User for RBAC (Redis 6.0+)
resource "aws_elasticache_user" "app_user" {
  count   = var.create_app_user ? 1 : 0
  user_id = "${var.project_name}-${var.environment}-app-user"
  user_name = var.app_user_name
  access_string = var.app_user_access_string
  engine = "REDIS"

  authentication_mode {
    type      = "password"
    passwords = [random_password.auth_token.result]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-redis-app-user"
  }
}

# ElastiCache User Group
resource "aws_elasticache_user_group" "main" {
  count         = var.create_app_user ? 1 : 0
  engine        = "REDIS"
  user_group_id = "${var.project_name}-${var.environment}-app-group"
  user_ids      = ["default", aws_elasticache_user.app_user[0].user_id]

  tags = {
    Name = "${var.project_name}-${var.environment}-redis-app-group"
  }
}