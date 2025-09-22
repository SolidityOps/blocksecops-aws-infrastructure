# Secrets Manager Module Variables

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "solidity-security"
}

variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
}

variable "kms_key_arn" {
  description = "ARN of KMS key for encryption"
  type        = string
}

variable "secrets" {
  description = "List of secrets to create and manage"
  type = list(object({
    name        = string
    path        = string
    description = string
    type        = string # database, api-key, oauth, etc.
    secret_data = map(string)

    # Rotation configuration
    rotation_enabled = bool
    rotation_days    = number

    # Database-specific (for rotation)
    db_engine   = optional(string)
    db_username = optional(string)
    db_name     = optional(string)

    # Cross-region replication
    replica_regions = optional(list(object({
      region      = string
      kms_key_arn = string
    })), [])

    tags = optional(map(string), {})
  }))
  default = []
}

variable "service_roles" {
  description = "IAM roles for services that need access to secrets"
  type = map(object({
    service             = string
    additional_policies = list(string)
  }))
  default = {}
}

# Lambda configuration for rotation
variable "lambda_subnet_ids" {
  description = "Subnet IDs for Lambda functions (for VPC access)"
  type        = list(string)
  default     = []
}

variable "lambda_security_group_ids" {
  description = "Security group IDs for Lambda functions"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Additional tags for all resources"
  type        = map(string)
  default     = {}
}