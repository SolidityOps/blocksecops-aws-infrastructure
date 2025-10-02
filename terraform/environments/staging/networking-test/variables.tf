# Variables for staging networking environment

variable "aws_region" {
  description = "AWS region for staging deployment"
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
  description = "CIDR block for staging VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# Deployment Configuration
variable "single_az_deployment" {
  description = "Deploy in single AZ for staging cost optimization"
  type        = bool
  default     = true
}

# NAT Configuration
variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for staging (set to false to use NAT instance)"
  type        = bool
  default     = false
}

variable "use_nat_instance" {
  description = "Use NAT instance for cost savings in staging"
  type        = bool
  default     = true
}

variable "nat_instance_type" {
  description = "Instance type for NAT instance"
  type        = string
  default     = "t3.nano"
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
  description = "Create bastion security group for staging access"
  type        = bool
  default     = false
}

# VPC Endpoints Configuration
variable "create_vpc_endpoints" {
  description = "Create VPC endpoints (minimal for staging cost optimization)"
  type        = bool
  default     = false
}

# Network Security
variable "create_network_acls" {
  description = "Create custom Network ACLs"
  type        = bool
  default     = true
}

# Monitoring Configuration
variable "enable_vpc_flow_logs" {
  description = "Enable VPC Flow Logs for security monitoring"
  type        = bool
  default     = true
}

variable "flow_logs_retention_days" {
  description = "VPC Flow Logs retention period in days"
  type        = number
  default     = 7
}

# Tagging
variable "additional_tags" {
  description = "Additional tags for staging resources"
  type        = map(string)
  default = {
    Purpose      = "development"
    AutoShutdown = "enabled"
    Monitoring   = "basic"
  }
}