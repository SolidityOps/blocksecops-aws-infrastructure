# Variables for Staging State Backend Configuration

variable "project" {
  description = "Project name used for resource naming"
  type        = string
  default     = "solidity-security"
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
  default     = true
}

variable "sns_topic_arn" {
  description = "SNS topic ARN for alarm notifications"
  type        = string
  default     = ""
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

# Tagging Variables
variable "additional_tags" {
  description = "Additional tags specific to the staging environment"
  type        = map(string)
  default = {
    Schedule      = "business-hours"
    CostOptimized = "true"
    DataClass     = "development"
  }
}