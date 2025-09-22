# Security Groups Module Variables

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "solidity-security"
}

variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where security groups will be created"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC"
  type        = string
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access public endpoints"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "enable_bastion_access" {
  description = "Enable bastion host for debugging database access"
  type        = bool
  default     = false
}

variable "additional_eks_ingress_rules" {
  description = "Additional ingress rules for EKS cluster security group"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
  default = []
}

variable "additional_alb_ingress_rules" {
  description = "Additional ingress rules for ALB security group"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
  default = []
}

variable "tags" {
  description = "Additional tags for security group resources"
  type        = map(string)
  default     = {}
}