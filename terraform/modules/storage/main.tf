# Storage Infrastructure Module for Task 1.3
# Provides PostgreSQL RDS and ElastiCache Redis for the Solidity Security Platform

terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Local values for consistent naming and tagging
locals {
  name_prefix = "${var.project}-${var.environment}"

  common_tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "terraform"
    Service     = "storage"
    Owner       = "devops"
    Project     = var.project
    Terraform   = "true"
    Module      = "storage"
  })
}

# Random password for PostgreSQL master user
resource "random_password" "postgresql_master_password" {
  length  = 32
  special = true
}

# AWS Secrets Manager secret for PostgreSQL credentials
resource "aws_secretsmanager_secret" "postgresql_credentials" {
  name                    = "${local.name_prefix}-postgresql-credentials"
  description             = "PostgreSQL master user credentials for ${var.environment}"
  recovery_window_in_days = var.environment == "production" ? 30 : 0

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-postgresql-credentials"
    Type = "database-credentials"
  })
}

resource "aws_secretsmanager_secret_version" "postgresql_credentials" {
  secret_id = aws_secretsmanager_secret.postgresql_credentials.id
  secret_string = jsonencode({
    username = var.postgresql_master_username
    password = random_password.postgresql_master_password.result
    engine   = "postgres"
    host     = aws_db_instance.postgresql.endpoint
    port     = aws_db_instance.postgresql.port
    dbname   = var.postgresql_database_name
  })

  depends_on = [aws_db_instance.postgresql]
}

# Enhanced monitoring IAM role for RDS
resource "aws_iam_role" "rds_enhanced_monitoring" {
  count = var.enable_enhanced_monitoring ? 1 : 0

  name = "${local.name_prefix}-rds-enhanced-monitoring"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  count = var.enable_enhanced_monitoring ? 1 : 0

  role       = aws_iam_role.rds_enhanced_monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# CloudWatch Log Groups for database logs
resource "aws_cloudwatch_log_group" "postgresql_logs" {
  for_each = toset(var.postgresql_enabled_logs)

  name              = "/aws/rds/instance/${local.name_prefix}-postgresql/${each.value}"
  retention_in_days = var.log_retention_days

  tags = merge(local.common_tags, {
    Name     = "${local.name_prefix}-postgresql-${each.value}-logs"
    Type     = "database-logs"
    Database = "postgresql"
    LogType  = each.value
  })
}