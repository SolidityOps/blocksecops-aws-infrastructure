# Storage Module Variables

# General variables
variable "project" {
  description = "Project name"
  type        = string
  default     = "solidity-security"
}

variable "environment" {
  description = "Environment name (staging, production)"
  type        = string
  validation {
    condition     = contains(["staging", "production"], var.environment)
    error_message = "Environment must be either staging or production."
  }
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}

# Network configuration
variable "db_subnet_group_name" {
  description = "DB subnet group name from networking module"
  type        = string
}

variable "elasticache_subnet_ids" {
  description = "Subnet IDs for ElastiCache from networking module"
  type        = list(string)
}

variable "postgresql_security_group_ids" {
  description = "Security group IDs for PostgreSQL"
  type        = list(string)
}

variable "redis_security_group_ids" {
  description = "Security group IDs for Redis"
  type        = list(string)
}

# PostgreSQL Configuration
variable "postgresql_engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "15.4"
}

variable "postgresql_instance_class" {
  description = "PostgreSQL instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "postgresql_allocated_storage" {
  description = "Initial allocated storage for PostgreSQL (GB)"
  type        = number
  default     = 20
}

variable "postgresql_max_allocated_storage" {
  description = "Maximum allocated storage for PostgreSQL (GB)"
  type        = number
  default     = 100
}

variable "postgresql_storage_type" {
  description = "Storage type for PostgreSQL"
  type        = string
  default     = "gp3"
  validation {
    condition     = contains(["gp2", "gp3", "io1", "io2"], var.postgresql_storage_type)
    error_message = "Storage type must be one of: gp2, gp3, io1, io2."
  }
}

variable "postgresql_database_name" {
  description = "Initial database name"
  type        = string
  default     = "solidity_security"
}

variable "postgresql_master_username" {
  description = "Master username for PostgreSQL"
  type        = string
  default     = "postgres"
}

variable "postgresql_port" {
  description = "Port for PostgreSQL"
  type        = number
  default     = 5432
}

variable "postgresql_backup_retention_period" {
  description = "Backup retention period for PostgreSQL (days)"
  type        = number
  default     = 7
}

variable "postgresql_backup_window" {
  description = "Backup window for PostgreSQL"
  type        = string
  default     = "03:00-04:00"
}

variable "postgresql_maintenance_window" {
  description = "Maintenance window for PostgreSQL"
  type        = string
  default     = "sun:04:00-sun:05:00"
}

variable "postgresql_multi_az" {
  description = "Enable Multi-AZ deployment for PostgreSQL"
  type        = bool
  default     = false
}

variable "postgresql_auto_minor_version_upgrade" {
  description = "Enable auto minor version upgrade for PostgreSQL"
  type        = bool
  default     = true
}

variable "postgresql_enabled_logs" {
  description = "List of log types to enable for PostgreSQL"
  type        = list(string)
  default     = ["postgresql"]
}

variable "postgresql_parameters" {
  description = "Custom parameters for PostgreSQL parameter group"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

# PostgreSQL Read Replica Configuration
variable "create_read_replica" {
  description = "Create a read replica for PostgreSQL"
  type        = bool
  default     = false
}

variable "postgresql_read_replica_instance_class" {
  description = "Instance class for PostgreSQL read replica"
  type        = string
  default     = "db.t3.micro"
}

# Redis Configuration
variable "redis_engine_version" {
  description = "Redis engine version"
  type        = string
  default     = "7.0"
}

variable "redis_node_type" {
  description = "Redis node type"
  type        = string
  default     = "cache.t3.micro"
}

variable "redis_port" {
  description = "Port for Redis"
  type        = number
  default     = 6379
}

variable "redis_num_cache_clusters" {
  description = "Number of cache clusters for Redis"
  type        = number
  default     = 1
}

variable "redis_automatic_failover_enabled" {
  description = "Enable automatic failover for Redis"
  type        = bool
  default     = false
}

variable "redis_multi_az_enabled" {
  description = "Enable Multi-AZ for Redis"
  type        = bool
  default     = false
}

variable "redis_snapshot_retention_limit" {
  description = "Number of days to retain Redis snapshots"
  type        = number
  default     = 1
}

variable "redis_snapshot_window" {
  description = "Snapshot window for Redis"
  type        = string
  default     = "03:00-05:00"
}

variable "redis_maintenance_window" {
  description = "Maintenance window for Redis"
  type        = string
  default     = "sun:05:00-sun:06:00"
}

variable "redis_auto_minor_version_upgrade" {
  description = "Enable auto minor version upgrade for Redis"
  type        = bool
  default     = true
}

variable "redis_parameters" {
  description = "Custom parameters for Redis parameter group"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

# Redis Session Store Configuration
variable "create_session_store" {
  description = "Create a separate Redis cluster for session storage"
  type        = bool
  default     = false
}

variable "redis_session_node_type" {
  description = "Redis node type for session store"
  type        = string
  default     = "cache.t3.micro"
}

variable "redis_session_num_cache_clusters" {
  description = "Number of cache clusters for Redis session store"
  type        = number
  default     = 1
}

# Security Configuration
variable "enable_encryption" {
  description = "Enable encryption at rest and in transit"
  type        = bool
  default     = true
}

# Monitoring Configuration
variable "enable_enhanced_monitoring" {
  description = "Enable enhanced monitoring for RDS"
  type        = bool
  default     = true
}

variable "enable_performance_insights" {
  description = "Enable Performance Insights for RDS"
  type        = bool
  default     = true
}

variable "performance_insights_retention_period" {
  description = "Performance Insights retention period (days)"
  type        = number
  default     = 7
}

variable "enable_redis_logging" {
  description = "Enable Redis slow log"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "CloudWatch log retention period (days)"
  type        = number
  default     = 14
}