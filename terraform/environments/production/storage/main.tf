# Production environment storage configuration
# High-availability and performance optimized deployment

terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    # Backend configuration will be provided via backend config file
    # terraform init -backend-config=backend.tfvars
  }
}

# Configure AWS Provider
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = "production"
      ManagedBy   = "terraform"
      Service     = "storage"
      Owner       = "devops"
      Project     = "solidity-security"
      CostCenter  = "production"
      Terraform   = "true"
      Compliance  = "required"
    }
  }
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Local values
locals {
  environment = "production"
  region      = data.aws_region.current.name
  account_id  = data.aws_caller_identity.current.account_id

  common_tags = {
    Environment      = local.environment
    Region           = local.region
    AccountId        = local.account_id
    DeployedBy       = "terraform"
    BackupPolicy     = "daily"
    Schedule         = "24x7"
    HighAvailability = "true"
    Compliance       = "required"
    DataClass        = "sensitive"
  }
}

# Get networking outputs from remote state
data "terraform_remote_state" "networking" {
  backend = "s3"
  config = {
    bucket = var.terraform_state_bucket
    key    = "environments/production/networking/terraform.tfstate"
    region = var.aws_region
  }
}

# Storage module
module "storage" {
  source = "../../../modules/storage"

  project     = var.project
  environment = local.environment

  # Network configuration from networking module
  db_subnet_group_name          = data.terraform_remote_state.networking.outputs.db_subnet_group_name
  elasticache_subnet_ids        = data.terraform_remote_state.networking.outputs.database_subnet_ids
  postgresql_security_group_ids = [data.terraform_remote_state.networking.outputs.postgresql_security_group_id]
  redis_security_group_ids      = [data.terraform_remote_state.networking.outputs.elasticache_security_group_id]

  # PostgreSQL configuration - production optimized
  postgresql_engine_version          = var.postgresql_engine_version
  postgresql_instance_class          = var.postgresql_instance_class
  postgresql_allocated_storage       = var.postgresql_allocated_storage
  postgresql_max_allocated_storage   = var.postgresql_max_allocated_storage
  postgresql_storage_type            = var.postgresql_storage_type
  postgresql_multi_az                = var.postgresql_multi_az
  postgresql_backup_retention_period = var.postgresql_backup_retention_period

  # PostgreSQL monitoring - enhanced for production
  enable_enhanced_monitoring            = var.enable_enhanced_monitoring
  enable_performance_insights           = var.enable_performance_insights
  performance_insights_retention_period = var.performance_insights_retention_period

  # Read replica - enabled for production
  create_read_replica                    = var.create_read_replica
  postgresql_read_replica_instance_class = var.postgresql_read_replica_instance_class

  # Redis configuration - production optimized
  redis_engine_version             = var.redis_engine_version
  redis_node_type                  = var.redis_node_type
  redis_num_cache_clusters         = var.redis_num_cache_clusters
  redis_automatic_failover_enabled = var.redis_automatic_failover_enabled
  redis_multi_az_enabled           = var.redis_multi_az_enabled
  redis_snapshot_retention_limit   = var.redis_snapshot_retention_limit

  # Session store - enabled for production
  create_session_store             = var.create_session_store
  redis_session_node_type          = var.redis_session_node_type
  redis_session_num_cache_clusters = var.redis_session_num_cache_clusters

  # Security - full encryption for production
  enable_encryption = var.enable_encryption

  # Monitoring - comprehensive for production
  enable_redis_logging = var.enable_redis_logging
  log_retention_days   = var.log_retention_days

  tags = merge(local.common_tags, var.additional_tags)
}