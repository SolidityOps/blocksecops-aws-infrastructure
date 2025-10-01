# Production Storage Environment Variables

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

# PostgreSQL Configuration - Production Optimized
variable "postgresql_engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "15.4"
}

variable "postgresql_instance_class" {
  description = "PostgreSQL instance class - production sized"
  type        = string
  default     = "db.r6g.large"
}

variable "postgresql_allocated_storage" {
  description = "Initial allocated storage for PostgreSQL (GB)"
  type        = number
  default     = 100
}

variable "postgresql_max_allocated_storage" {
  description = "Maximum allocated storage for PostgreSQL (GB)"
  type        = number
  default     = 1000
}

variable "postgresql_storage_type" {
  description = "Storage type for PostgreSQL - high performance"
  type        = string
  default     = "gp3"
}

variable "postgresql_multi_az" {
  description = "Enable Multi-AZ deployment - enabled for production HA"
  type        = bool
  default     = true
}

variable "postgresql_backup_retention_period" {
  description = "Backup retention period - extended for production"
  type        = number
  default     = 30
}

# PostgreSQL Read Replica - Enabled for production
variable "create_read_replica" {
  description = "Create a read replica - enabled for production"
  type        = bool
  default     = true
}

variable "postgresql_read_replica_instance_class" {
  description = "PostgreSQL read replica instance class"
  type        = string
  default     = "db.r6g.large"
}

# Redis Configuration - Production Optimized
variable "redis_engine_version" {
  description = "Redis engine version"
  type        = string
  default     = "7.0"
}

variable "redis_node_type" {
  description = "Redis node type - production sized"
  type        = string
  default     = "cache.r6g.large"
}

variable "redis_num_cache_clusters" {
  description = "Number of cache clusters - multiple for HA"
  type        = number
  default     = 3
}

variable "redis_automatic_failover_enabled" {
  description = "Enable automatic failover - enabled for production"
  type        = bool
  default     = true
}

variable "redis_multi_az_enabled" {
  description = "Enable Multi-AZ - enabled for production HA"
  type        = bool
  default     = true
}

variable "redis_snapshot_retention_limit" {
  description = "Snapshot retention limit - extended for production"
  type        = number
  default     = 7
}

# Session Store Configuration - Enabled for production
variable "create_session_store" {
  description = "Create separate Redis for sessions - enabled for production"
  type        = bool
  default     = true
}

variable "redis_session_node_type" {
  description = "Redis session node type"
  type        = string
  default     = "cache.r6g.large"
}

variable "redis_session_num_cache_clusters" {
  description = "Number of cache clusters for Redis session store"
  type        = number
  default     = 2
}

# Security Configuration
variable "enable_encryption" {
  description = "Enable encryption - always enabled for production"
  type        = bool
  default     = true
}

# Monitoring Configuration - Enhanced for production
variable "enable_enhanced_monitoring" {
  description = "Enable enhanced monitoring - enabled for production"
  type        = bool
  default     = true
}

variable "enable_performance_insights" {
  description = "Enable Performance Insights - enabled for production"
  type        = bool
  default     = true
}

variable "performance_insights_retention_period" {
  description = "Performance Insights retention period - 7 days (free) or 731 days (paid)"
  type        = number
  default     = 731
}

variable "enable_redis_logging" {
  description = "Enable Redis logging - enabled for production"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Log retention period - extended for production compliance"
  type        = number
  default     = 30
}