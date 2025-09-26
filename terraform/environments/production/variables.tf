# Variables for Production Environment

variable "aws_region" {
  description = "AWS region for production environment"
  type        = string
  default     = "us-west-2"
}

variable "vpc_cidr" {
  description = "CIDR block for production VPC"
  type        = string
  default     = "10.1.0.0/16"  # Different CIDR range from staging
}

variable "public_subnet_cidr" {
  description = "CIDR block for production public subnet"
  type        = string
  default     = "10.1.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block for production private subnet"
  type        = string
  default     = "10.1.2.0/24"
}

variable "log_retention_days" {
  description = "VPC Flow Logs retention period for production"
  type        = number
  default     = 90  # Longer retention for production compliance
}

variable "common_tags" {
  description = "Common tags for production resources"
  type        = map(string)
  default = {
    Environment = "production"
    Project     = "SoliditySecurityPlatform"
    ManagedBy   = "Terraform"
    Owner       = "DevOps"
    CostCenter  = "Production"
    Backup      = "Required"
  }
}

# ElastiCache Redis Configuration
variable "redis_node_type" {
  description = "ElastiCache Redis node type for production"
  type        = string
  default     = "cache.t3.small"  # Larger instance for production
}

variable "redis_num_cache_nodes" {
  description = "Number of cache nodes in the Redis cluster for production"
  type        = number
  default     = 1  # Single node for MVP, can scale later
}

variable "backup_retention_limit" {
  description = "Number of days for which ElastiCache retains automatic cache cluster backups"
  type        = number
  default     = 7  # Longer retention for production
}

variable "backup_window" {
  description = "Daily time range for automated backups (UTC)"
  type        = string
  default     = "03:00-05:00"
}

variable "maintenance_window" {
  description = "Weekly time range for system maintenance (UTC)"
  type        = string
  default     = "sun:05:00-sun:07:00"
}

variable "snapshot_window" {
  description = "Daily time range for ElastiCache snapshots (UTC)"
  type        = string
  default     = "02:00-03:00"
}