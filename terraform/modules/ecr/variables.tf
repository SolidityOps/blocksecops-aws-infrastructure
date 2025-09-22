# ECR Module Variables

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "solidity-security"
}

variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
}

variable "repositories" {
  description = "List of ECR repository names to create"
  type        = list(string)
  default = [
    "api-service",
    "tool-integration-service",
    "orchestration-service",
    "intelligence-engine-service",
    "data-service",
    "notification-service",
    "frontend"
  ]
}

# Repository Configuration
variable "image_tag_mutability" {
  description = "The tag mutability setting for the repository (MUTABLE or IMMUTABLE)"
  type        = string
  default     = "MUTABLE"
}

variable "scan_on_push" {
  description = "Indicates whether images are scanned after being pushed to the repository"
  type        = bool
  default     = true
}

variable "encryption_type" {
  description = "The encryption type to use for the repository (AES256 or KMS)"
  type        = string
  default     = "KMS"
}

variable "kms_key_arn" {
  description = "ARN of KMS key for encryption"
  type        = string
  default     = null
}

# Lifecycle Policy Configuration
variable "max_image_count" {
  description = "Maximum number of images to keep"
  type        = number
  default     = 10
}

variable "untagged_image_retention_days" {
  description = "Number of days to retain untagged images"
  type        = number
  default     = 1
}

# Cross-region Replication
variable "enable_cross_region_replication" {
  description = "Enable cross-region replication for ECR repositories"
  type        = bool
  default     = false
}

variable "replication_destination_region" {
  description = "Destination region for cross-region replication"
  type        = string
  default     = "us-west-2"
}

# Registry Scanning
variable "enable_registry_scanning" {
  description = "Enable registry-level scanning configuration"
  type        = bool
  default     = false
}

variable "registry_scan_type" {
  description = "Type of registry scanning (BASIC or ENHANCED)"
  type        = string
  default     = "BASIC"
}

variable "registry_scan_rules" {
  description = "Registry scanning rules"
  type = list(object({
    scan_frequency = string
    filter         = string
    filter_type    = string
  }))
  default = [
    {
      scan_frequency = "SCAN_ON_PUSH"
      filter         = "*"
      filter_type    = "WILDCARD"
    }
  ]
}

# Registry Policy
variable "enable_registry_policy" {
  description = "Enable registry-level policy"
  type        = bool
  default     = false
}

# Pull Through Cache
variable "pull_through_cache_rules" {
  description = "Pull through cache rules for external registries"
  type = map(object({
    upstream_registry_url = string
  }))
  default = {}
}

# Monitoring and Logging
variable "enable_cloudwatch_logging" {
  description = "Enable CloudWatch logging for ECR"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}

variable "enable_scan_result_notifications" {
  description = "Enable notifications for scan results"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags for ECR resources"
  type        = map(string)
  default     = {}
}