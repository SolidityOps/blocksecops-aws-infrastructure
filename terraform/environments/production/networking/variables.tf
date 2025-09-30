# Variables for production networking environment

variable "aws_region" {
  description = "AWS region for production deployment"
  type        = string
  default     = "us-west-2"
}

variable "project" {
  description = "Project name"
  type        = string
  default     = "solidity-security"
}

# VPC Configuration
variable "vpc_cidr" {
  description = "CIDR block for production VPC"
  type        = string
  default     = "10.1.0.0/16"
}

# Deployment Configuration
variable "single_az_deployment" {
  description = "Deploy in single AZ (false for production high availability)"
  type        = bool
  default     = false
}

variable "max_azs" {
  description = "Maximum number of availability zones for production"
  type        = number
  default     = 3
}

# NAT Configuration
variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for production reliability"
  type        = bool
  default     = true
}

variable "use_nat_instance" {
  description = "Use NAT instance instead of NAT gateway"
  type        = bool
  default     = false
}

# Subnet Configuration
variable "create_database_subnets" {
  description = "Create dedicated database subnets"
  type        = bool
  default     = true
}

# Security Groups
variable "create_eks_security_groups" {
  description = "Create EKS security groups"
  type        = bool
  default     = true
}

variable "create_alb_security_group" {
  description = "Create ALB security group"
  type        = bool
  default     = true
}

variable "create_database_security_groups" {
  description = "Create database security groups"
  type        = bool
  default     = true
}

variable "create_bastion_security_group" {
  description = "Create bastion security group for production access"
  type        = bool
  default     = true
}

variable "bastion_allowed_cidr_blocks" {
  description = "CIDR blocks allowed SSH access to bastion host"
  type        = list(string)
  default     = []
}

# VPC Endpoints Configuration
variable "create_vpc_endpoints" {
  description = "Create VPC endpoints for production cost optimization and security"
  type        = bool
  default     = true
}

# Network Security
variable "create_network_acls" {
  description = "Create custom Network ACLs for enhanced security"
  type        = bool
  default     = true
}

# Monitoring Configuration
variable "enable_vpc_flow_logs" {
  description = "Enable VPC Flow Logs for production security monitoring"
  type        = bool
  default     = true
}

variable "flow_logs_retention_days" {
  description = "VPC Flow Logs retention period in days for production"
  type        = number
  default     = 30
}

# Tagging
variable "additional_tags" {
  description = "Additional tags for production resources"
  type        = map(string)
  default = {
    Purpose       = "production"
    HighAvailability = "required"
    Monitoring    = "enhanced"
    Compliance    = "required"
    DataClass     = "confidential"
  }
}