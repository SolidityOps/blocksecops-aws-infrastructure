# Staging Storage Environment Variables

# General variables
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "project" {
  description = "Project name"
  type        = string
  default     = "solidity-security"
}

variable "terraform_state_bucket" {
  description = "S3 bucket for Terraform state"
  type        = string
  default     = "solidity-security-terraform-state"
}

variable "additional_tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}

# PostgreSQL Configuration - Staging Optimized
variable "postgresql_engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "15.4"
}

variable "postgresql_instance_class" {
  description = "PostgreSQL instance class - cost optimized for staging"
  type        = string
  default     = "db.t3.micro"
}

variable "postgresql_allocated_storage" {
  description = "Initial allocated storage for PostgreSQL (GB) - minimal for staging"
  type        = number
  default     = 20
}

variable "postgresql_max_allocated_storage" {
  description = "Maximum allocated storage for PostgreSQL (GB)"
  type        = number
  default     = 50
}

variable "postgresql_storage_type" {
  description = "Storage type for PostgreSQL - gp3 for cost optimization"
  type        = string
  default     = "gp3"
}

variable "postgresql_multi_az" {
  description = "Enable Multi-AZ deployment - disabled for staging cost optimization"
  type        = bool
  default     = false
}

variable "postgresql_backup_retention_period" {
  description = "Backup retention period - minimal for staging"
  type        = number
  default     = 3
}

# PostgreSQL Read Replica - Disabled for staging
variable "create_read_replica" {
  description = "Create a read replica - disabled for staging cost optimization"
  type        = bool
  default     = false
}

# Redis Configuration - Staging Optimized
variable "redis_engine_version" {
  description = "Redis engine version"
  type        = string
  default     = "7.0"
}

variable "redis_node_type" {
  description = "Redis node type - cost optimized for staging"
  type        = string
  default     = "cache.t3.micro"
}

variable "redis_num_cache_clusters" {
  description = "Number of cache clusters - single node for staging"
  type        = number
  default     = 1
}

variable "redis_automatic_failover_enabled" {
  description = "Enable automatic failover - disabled for staging"
  type        = bool
  default     = false
}

variable "redis_multi_az_enabled" {
  description = "Enable Multi-AZ - disabled for staging cost optimization"
  type        = bool
  default     = false
}

variable "redis_snapshot_retention_limit" {
  description = "Snapshot retention limit - minimal for staging"
  type        = number
  default     = 1
}

# Session Store Configuration
variable "create_session_store" {
  description = "Create separate Redis for sessions - optional for staging"
  type        = bool
  default     = false
}

variable "redis_session_node_type" {
  description = "Redis session node type"
  type        = string
  default     = "cache.t3.micro"
}

# Security Configuration
variable "enable_encryption" {
  description = "Enable encryption - always enabled for security"
  type        = bool
  default     = true
}

# Monitoring Configuration - Basic for staging
variable "enable_enhanced_monitoring" {
  description = "Enable enhanced monitoring - basic for staging"
  type        = bool
  default     = false
}

variable "enable_performance_insights" {
  description = "Enable Performance Insights - basic for staging"
  type        = bool
  default     = false
}

variable "performance_insights_retention_period" {
  description = "Performance Insights retention period"
  type        = number
  default     = 7
}

variable "enable_redis_logging" {
  description = "Enable Redis logging"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Log retention period - shorter for staging cost optimization"
  type        = number
  default     = 7
}