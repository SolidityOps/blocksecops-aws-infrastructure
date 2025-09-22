# Development Environment Variables

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "solidity-security"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# Domain configuration for Cloudflare
variable "domain_name" {
  description = "Domain name (managed by Cloudflare)"
  type        = string
  default     = "advancedblockchainsecurity.com"
}

variable "subdomain_prefix" {
  description = "Subdomain prefix for this environment"
  type        = string
  default     = "dev"
}

# EKS Configuration
variable "kubernetes_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
  default     = "1.27"
}

variable "node_instance_types" {
  description = "Instance types for EKS node groups"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_desired_size" {
  description = "Desired number of nodes in EKS node group"
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum number of nodes in EKS node group"
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Maximum number of nodes in EKS node group"
  type        = number
  default     = 5
}

# RDS Configuration
variable "rds_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "rds_allocated_storage" {
  description = "Initial allocated storage for RDS"
  type        = number
  default     = 20
}

variable "rds_max_allocated_storage" {
  description = "Maximum allocated storage for RDS"
  type        = number
  default     = 100
}

variable "rds_backup_retention_period" {
  description = "Backup retention period for RDS"
  type        = number
  default     = 3
}

# ElastiCache Configuration
variable "elasticache_node_type" {
  description = "ElastiCache node type"
  type        = string
  default     = "cache.t3.micro"
}

variable "elasticache_num_cache_clusters" {
  description = "Number of cache clusters"
  type        = number
  default     = 1
}

# Security Configuration
variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access public endpoints"
  type        = list(string)
  default     = ["0.0.0.0/0"] # Restrict this in production
}

# Cost optimization
variable "enable_nat_gateway" {
  description = "Enable NAT Gateway (set to false to reduce costs)"
  type        = bool
  default     = true
}

variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs"
  type        = bool
  default     = false # Disabled to reduce costs in development
}

# Monitoring and logging
variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}

variable "enable_detailed_monitoring" {
  description = "Enable detailed monitoring for resources"
  type        = bool
  default     = false # Disabled to reduce costs in development
}

# Tags
variable "additional_tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default = {
    CostCenter = "development"
    Owner      = "platform-team"
  }
}