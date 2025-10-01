# Production environment Terraform state backend configuration
# This creates the S3 bucket and DynamoDB table for remote state management

terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  # Note: This configuration itself uses local state
  # Once the backend is created, other configurations will use remote state
}

# Configure AWS Provider
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = "production"
      ManagedBy   = "terraform"
      Component   = "state-backend"
      Owner       = "devops"
      Project     = "solidity-security"
      CostCenter  = "engineering"
      Terraform   = "true"
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
    Environment   = local.environment
    Region        = local.region
    AccountId     = local.account_id
    DeployedBy    = "terraform"
    LastUpdated   = timestamp()
    BackupPolicy  = "high-availability"
    Schedule      = "24x7"
    CostOptimized = "false"
  }
}

# State backend module
module "state_backend" {
  source = "../../../modules/state-backend"

  project     = var.project
  environment = local.environment
  aws_region  = local.region

  # S3 Configuration
  state_retention_days = var.state_retention_days
  enable_access_logging = var.enable_access_logging
  enable_notifications = var.enable_notifications

  # DynamoDB Configuration
  enable_point_in_time_recovery = var.enable_point_in_time_recovery
  enable_lock_ttl               = var.enable_lock_ttl

  # Monitoring Configuration
  enable_monitoring = var.enable_monitoring
  sns_topic_arn    = var.sns_topic_arn

  # Security Configuration
  enable_kms_encryption = var.enable_kms_encryption
  kms_key_id           = var.kms_key_id

  # Cross-Account Access
  trusted_account_ids = var.trusted_account_ids
  trusted_role_arns  = var.trusted_role_arns

  # Tags
  common_tags = merge(local.common_tags, var.additional_tags)
  additional_tags = {
    Purpose       = "terraform-state-backend"
    Criticality   = "critical"
    DataClass     = "internal"
    BackupTier    = "high-availability"
  }
}