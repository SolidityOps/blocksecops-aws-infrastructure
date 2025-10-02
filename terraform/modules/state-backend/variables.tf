# Variables for Terraform State Backend Module

variable "project" {
  description = "Project name used for resource naming"
  type        = string
  default     = "solidity-security"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Environment name (staging, production)"
  type        = string

  validation {
    condition     = contains(["staging", "production"], var.environment)
    error_message = "Environment must be either 'staging' or 'production'."
  }
}

variable "aws_region" {
  description = "AWS region for state backend resources"
  type        = string
  default     = "us-west-2"
}

# S3 Configuration Variables
variable "state_retention_days" {
  description = "Number of days to retain old versions of Terraform state files"
  type        = number
  default     = 90

  validation {
    condition     = var.state_retention_days >= 30 && var.state_retention_days <= 365
    error_message = "State retention days must be between 30 and 365."
  }
}

variable "enable_access_logging" {
  description = "Enable S3 access logging for the state bucket"
  type        = bool
  default     = false
}

variable "access_log_bucket" {
  description = "S3 bucket for access logs (required if enable_access_logging is true)"
  type        = string
  default     = ""
}

variable "enable_notifications" {
  description = "Enable S3 bucket notifications for state changes"
  type        = bool
  default     = false
}

# DynamoDB Configuration Variables
variable "enable_point_in_time_recovery" {
  description = "Enable point-in-time recovery for DynamoDB state lock table"
  type        = bool
  default     = true
}

variable "enable_lock_ttl" {
  description = "Enable TTL for DynamoDB locks (helps with orphaned locks)"
  type        = bool
  default     = false
}

# Monitoring Configuration Variables
variable "enable_monitoring" {
  description = "Enable CloudWatch monitoring and alarms for state backend"
  type        = bool
  default     = false
}

variable "sns_topic_arn" {
  description = "SNS topic ARN for alarm notifications"
  type        = string
  default     = ""
}

# Tagging Variables
variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    ManagedBy = "terraform"
    Module    = "state-backend"
  }
}

variable "additional_tags" {
  description = "Additional tags specific to the state backend"
  type        = map(string)
  default     = {}
}

# Security Configuration Variables
variable "enable_kms_encryption" {
  description = "Use KMS encryption instead of AES256 for S3 bucket"
  type        = bool
  default     = false
}

variable "kms_key_id" {
  description = "KMS key ID for S3 bucket encryption (required if enable_kms_encryption is true)"
  type        = string
  default     = ""
}

variable "bucket_policy_statements" {
  description = "Additional bucket policy statements"
  type = list(object({
    sid       = string
    effect    = string
    principal = any
    action    = list(string)
    resource  = list(string)
    condition = map(any)
  }))
  default = []
}

# Cross-Account Access Variables
variable "trusted_account_ids" {
  description = "List of AWS account IDs that can access the state backend"
  type        = list(string)
  default     = []
}

variable "trusted_role_arns" {
  description = "List of IAM role ARNs that can access the state backend"
  type        = list(string)
  default     = []
}

# Backup Configuration Variables
variable "enable_cross_region_replication" {
  description = "Enable cross-region replication for state bucket"
  type        = bool
  default     = false
}

variable "replication_destination_bucket" {
  description = "Destination bucket for cross-region replication"
  type        = string
  default     = ""
}

variable "replication_destination_region" {
  description = "Destination region for cross-region replication"
  type        = string
  default     = ""
}