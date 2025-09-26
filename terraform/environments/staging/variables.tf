# Variables for Staging Environment

variable "aws_region" {
  description = "AWS region for staging environment"
  type        = string
  default     = "us-west-2"
}

variable "vpc_cidr" {
  description = "CIDR block for staging VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for staging public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block for staging private subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "log_retention_days" {
  description = "VPC Flow Logs retention period for staging"
  type        = number
  default     = 7  # Shorter retention for staging to reduce costs
}

variable "common_tags" {
  description = "Common tags for staging resources"
  type        = map(string)
  default = {
    Environment = "staging"
    Project     = "SoliditySecurityPlatform"
    ManagedBy   = "Terraform"
    Owner       = "DevOps"
    CostCenter  = "Development"
  }
}

# ElastiCache Redis Configuration
variable "redis_node_type" {
  description = "ElastiCache Redis node type for staging"
  type        = string
  default     = "cache.t3.micro"  # Cost-optimized for staging
}

variable "redis_num_cache_nodes" {
  description = "Number of cache nodes in the Redis cluster for staging"
  type        = number
  default     = 1  # Single node for staging
}

variable "backup_retention_limit" {
  description = "Number of days for which ElastiCache retains automatic cache cluster backups"
  type        = number
  default     = 3  # Shorter retention for staging
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