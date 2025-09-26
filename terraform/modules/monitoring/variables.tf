# Variables for Monitoring Module

variable "environment" {
  description = "Environment name (staging, production)"
  type        = string
  validation {
    condition     = contains(["staging", "production"], var.environment)
    error_message = "Environment must be either 'staging' or 'production'."
  }
}

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-west-2"
}

variable "vpc_id" {
  description = "ID of the VPC to monitor"
  type        = string
}

variable "log_retention_days" {
  description = "Number of days to retain VPC Flow Logs in S3"
  type        = number
  default     = 30
  validation {
    condition     = var.log_retention_days > 0 && var.log_retention_days <= 3653
    error_message = "Log retention days must be between 1 and 3653 days."
  }
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "SoliditySecurityPlatform"
    ManagedBy   = "Terraform"
    Owner       = "DevOps"
  }
}