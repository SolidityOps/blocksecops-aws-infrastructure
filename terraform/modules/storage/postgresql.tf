# PostgreSQL RDS Instance Configuration

# KMS key for RDS encryption
resource "aws_kms_key" "postgresql" {
  count = var.enable_encryption ? 1 : 0

  description             = "KMS key for PostgreSQL RDS encryption"
  deletion_window_in_days = var.environment == "production" ? 30 : 7

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-postgresql-kms"
    Type = "encryption-key"
  })
}

resource "aws_kms_alias" "postgresql" {
  count = var.enable_encryption ? 1 : 0

  name          = "alias/${local.name_prefix}-postgresql"
  target_key_id = aws_kms_key.postgresql[0].key_id
}

# PostgreSQL parameter group
resource "aws_db_parameter_group" "postgresql" {
  family = "postgres${split(".", var.postgresql_engine_version)[0]}"
  name   = "${local.name_prefix}-postgresql-params"

  description = "PostgreSQL parameter group for ${var.environment}"

  # Performance tuning parameters
  dynamic "parameter" {
    for_each = var.postgresql_parameters
    content {
      name  = parameter.value.name
      value = parameter.value.value
    }
  }

  # Common PostgreSQL parameters for application workloads
  parameter {
    name  = "shared_preload_libraries"
    value = "pg_stat_statements"
  }

  parameter {
    name  = "log_statement"
    value = var.environment == "production" ? "ddl" : "all"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = var.environment == "production" ? "1000" : "500"
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-postgresql-params"
    Type = "parameter-group"
  })
}

# PostgreSQL option group
resource "aws_db_option_group" "postgresql" {
  name                     = "${local.name_prefix}-postgresql-options"
  option_group_description = "PostgreSQL option group for ${var.environment}"
  engine_name              = "postgres"
  major_engine_version     = split(".", var.postgresql_engine_version)[0]

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-postgresql-options"
    Type = "option-group"
  })
}

# PostgreSQL RDS Instance
resource "aws_db_instance" "postgresql" {
  identifier = "${local.name_prefix}-postgresql"

  # Engine configuration
  engine         = "postgres"
  engine_version = var.postgresql_engine_version
  instance_class = var.postgresql_instance_class

  # Storage configuration
  allocated_storage     = var.postgresql_allocated_storage
  max_allocated_storage = var.postgresql_max_allocated_storage
  storage_type          = var.postgresql_storage_type
  storage_encrypted     = var.enable_encryption
  kms_key_id            = var.enable_encryption ? aws_kms_key.postgresql[0].arn : null

  # Database configuration
  db_name  = var.postgresql_database_name
  username = var.postgresql_master_username
  password = random_password.postgresql_master_password.result

  # Network configuration
  db_subnet_group_name   = var.db_subnet_group_name
  vpc_security_group_ids = var.postgresql_security_group_ids
  publicly_accessible    = false
  port                   = var.postgresql_port

  # Parameter and option groups
  parameter_group_name = aws_db_parameter_group.postgresql.name
  option_group_name    = aws_db_option_group.postgresql.name

  # Backup configuration
  backup_retention_period  = var.postgresql_backup_retention_period
  backup_window            = var.postgresql_backup_window
  maintenance_window       = var.postgresql_maintenance_window
  copy_tags_to_snapshot    = true
  delete_automated_backups = var.environment != "production"

  # Monitoring and logging
  monitoring_interval = var.enable_enhanced_monitoring ? 60 : 0
  monitoring_role_arn = var.enable_enhanced_monitoring ? aws_iam_role.rds_enhanced_monitoring[0].arn : null

  enabled_cloudwatch_logs_exports       = var.postgresql_enabled_logs
  performance_insights_enabled          = var.enable_performance_insights
  performance_insights_kms_key_id       = var.enable_performance_insights && var.enable_encryption ? aws_kms_key.postgresql[0].arn : null
  performance_insights_retention_period = var.enable_performance_insights ? var.performance_insights_retention_period : null

  # High availability
  multi_az = var.postgresql_multi_az

  # Security
  deletion_protection       = var.environment == "production"
  skip_final_snapshot       = var.environment != "production"
  final_snapshot_identifier = var.environment == "production" ? "${local.name_prefix}-postgresql-final-snapshot" : null

  # Auto minor version upgrade
  auto_minor_version_upgrade = var.postgresql_auto_minor_version_upgrade

  tags = merge(local.common_tags, {
    Name   = "${local.name_prefix}-postgresql"
    Type   = "database"
    Engine = "postgresql"
  })

  depends_on = [
    aws_cloudwatch_log_group.postgresql_logs
  ]
}

# Read replica for production environment
resource "aws_db_instance" "postgresql_read_replica" {
  count = var.create_read_replica ? 1 : 0

  identifier = "${local.name_prefix}-postgresql-read-replica"

  # Read replica configuration
  replicate_source_db = aws_db_instance.postgresql.identifier

  # Instance configuration
  instance_class = var.postgresql_read_replica_instance_class

  # Network configuration
  publicly_accessible = false

  # Monitoring
  monitoring_interval = var.enable_enhanced_monitoring ? 60 : 0
  monitoring_role_arn = var.enable_enhanced_monitoring ? aws_iam_role.rds_enhanced_monitoring[0].arn : null

  performance_insights_enabled          = var.enable_performance_insights
  performance_insights_kms_key_id       = var.enable_performance_insights && var.enable_encryption ? aws_kms_key.postgresql[0].arn : null
  performance_insights_retention_period = var.enable_performance_insights ? var.performance_insights_retention_period : null

  # Auto minor version upgrade
  auto_minor_version_upgrade = var.postgresql_auto_minor_version_upgrade

  # Security
  skip_final_snapshot = true

  tags = merge(local.common_tags, {
    Name   = "${local.name_prefix}-postgresql-read-replica"
    Type   = "database-read-replica"
    Engine = "postgresql"
  })
}