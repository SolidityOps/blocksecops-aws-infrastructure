# Variables for networking module

variable "project" {
  description = "Project name used for resource naming"
  type        = string
  default     = "solidity-security"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]+$", var.project))
    error_message = "Project name must contain only alphanumeric characters and hyphens."
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

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# VPC Configuration
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}

variable "subnet_bits" {
  description = "Number of additional bits with which to extend the VPC CIDR for subnet creation"
  type        = number
  default     = 8

  validation {
    condition     = var.subnet_bits >= 4 && var.subnet_bits <= 12
    error_message = "Subnet bits must be between 4 and 12."
  }
}

# Availability Zone Configuration
variable "single_az_deployment" {
  description = "Whether to deploy in single AZ for cost optimization (MVP)"
  type        = bool
  default     = true
}

variable "max_azs" {
  description = "Maximum number of availability zones to use"
  type        = number
  default     = 3

  validation {
    condition     = var.max_azs >= 1 && var.max_azs <= 6
    error_message = "Max AZs must be between 1 and 6."
  }
}

# NAT Gateway Configuration
variable "enable_nat_gateway" {
  description = "Whether to create NAT gateways for private subnet internet access"
  type        = bool
  default     = true
}

variable "use_nat_instance" {
  description = "Use NAT instance instead of NAT gateway for cost savings"
  type        = bool
  default     = false
}

variable "nat_instance_type" {
  description = "Instance type for NAT instance"
  type        = string
  default     = "t3.nano"
}

variable "nat_instance_ami" {
  description = "AMI ID for NAT instance (leave empty for automatic selection)"
  type        = string
  default     = ""
}

variable "nat_instance_ssh_allowed_cidr_blocks" {
  description = "CIDR blocks allowed SSH access to NAT instance"
  type        = list(string)
  default     = []
}

# Database Subnet Configuration
variable "create_database_subnets" {
  description = "Whether to create separate database subnets"
  type        = bool
  default     = true
}

variable "database_subnet_internet_access" {
  description = "Whether database subnets should have internet access via NAT"
  type        = bool
  default     = false
}

# Security Group Configuration
variable "create_eks_security_groups" {
  description = "Whether to create EKS-specific security groups"
  type        = bool
  default     = true
}

variable "create_alb_security_group" {
  description = "Whether to create ALB security group"
  type        = bool
  default     = true
}

variable "create_database_security_groups" {
  description = "Whether to create database security groups"
  type        = bool
  default     = true
}

variable "create_bastion_security_group" {
  description = "Whether to create bastion host security group"
  type        = bool
  default     = false
}

variable "bastion_allowed_cidr_blocks" {
  description = "CIDR blocks allowed SSH access to bastion host"
  type        = list(string)
  default     = []
}

# VPC Endpoints Configuration
variable "create_vpc_endpoints" {
  description = "Whether to create VPC endpoints for AWS services"
  type        = bool
  default     = true
}

# Network ACLs Configuration
variable "create_network_acls" {
  description = "Whether to create custom Network ACLs"
  type        = bool
  default     = true
}

# VPC Flow Logs Configuration
variable "enable_vpc_flow_logs" {
  description = "Whether to enable VPC Flow Logs"
  type        = bool
  default     = true
}

variable "flow_logs_retention_days" {
  description = "Number of days to retain VPC Flow Logs"
  type        = number
  default     = 14

  validation {
    condition = contains([
      1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653
    ], var.flow_logs_retention_days)
    error_message = "Flow logs retention days must be a valid CloudWatch Logs retention period."
  }
}