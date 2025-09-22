# ElastiCache Module Variables

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "solidity-security"
}

variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for ElastiCache subnet group"
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of security group IDs for ElastiCache cluster"
  type        = list(string)
}

variable "kms_key_arn" {
  description = "ARN of KMS key for encryption"
  type        = string
}

# Redis Configuration
variable "redis_version" {
  description = "Redis version"
  type        = string
  default     = "7.0"
}

variable "node_type" {
  description = "ElastiCache node type"
  type        = string
  default     = "cache.t3.micro"
}

variable "port" {
  description = "Port for Redis connections"
  type        = number
  default     = 6379
}

variable "num_cache_clusters" {
  description = "Number of cache clusters (nodes) in replication group"
  type        = number
  default     = 2
}

variable "parameter_group_family" {
  description = "ElastiCache parameter group family"
  type        = string
  default     = "redis7"
}

variable "maxmemory_policy" {
  description = "Redis maxmemory policy"
  type        = string
  default     = "allkeys-lru"
}

# High Availability
variable "multi_az_enabled" {
  description = "Enable Multi-AZ deployment"
  type        = bool
  default     = true
}

variable "automatic_failover_enabled" {
  description = "Enable automatic failover"
  type        = bool
  default     = true
}

# Maintenance
variable "maintenance_window" {
  description = "Preferred maintenance window (UTC)"
  type        = string
  default     = "sun:03:00-sun:04:00"
}

variable "auto_minor_version_upgrade" {
  description = "Enable automatic minor version upgrades"
  type        = bool
  default     = true
}

variable "notification_topic_arn" {
  description = "ARN of SNS topic for notifications"
  type        = string
  default     = null
}

# Backup Configuration
variable "snapshot_retention_limit" {
  description = "Number of days for which ElastiCache retains automatic snapshots"
  type        = number
  default     = 7
}

variable "snapshot_window" {
  description = "Daily time range during which automated backups are created"
  type        = string
  default     = "02:00-03:00"
}

variable "final_snapshot_identifier" {
  description = "Name of final snapshot when cluster is deleted"
  type        = string
  default     = null
}

# Logging
variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}

# Global Datastore
variable "create_global_replication_group" {
  description = "Create a global replication group for cross-region replication"
  type        = bool
  default     = false
}

# User Management (Redis 6.0+)
variable "create_app_user" {
  description = "Create application user for RBAC"
  type        = bool
  default     = false
}

variable "app_user_name" {
  description = "Name for application user"
  type        = string
  default     = "app-user"
}

variable "app_user_access_string" {
  description = "Access string for application user"
  type        = string
  default     = "on ~* +@all"
}

variable "tags" {
  description = "Additional tags for ElastiCache resources"
  type        = map(string)
  default     = {}
}