# IAM Module Variables

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "solidity-security"
}

variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the EKS OIDC provider"
  type        = string
}

variable "service_accounts" {
  description = "Service accounts that need IAM roles"
  type = map(object({
    namespace            = string
    service_account_name = string
    policy_arns          = list(string)
    custom_policy        = optional(string)
  }))
  default = {}
}

variable "enable_cert_manager_role" {
  description = "Enable IAM role for cert-manager (disabled - using Cloudflare Enterprise)"
  type        = bool
  default     = false
}

variable "enable_cluster_autoscaler_role" {
  description = "Enable IAM role for cluster autoscaler"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags for IAM resources"
  type        = map(string)
  default     = {}
}