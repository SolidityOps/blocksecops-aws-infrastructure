# Variables for Cache Monitoring Module

variable "environment" {
  description = "Environment name (staging, production)"
  type        = string
  validation {
    condition     = contains(["staging", "production"], var.environment)
    error_message = "Environment must be either 'staging' or 'production'."
  }
}

variable "redis_cluster_id" {
  description = "ElastiCache Redis cluster ID"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# CloudWatch alarm thresholds
variable "cpu_threshold" {
  description = "CPU utilization threshold for Redis alarm"
  type        = number
  default     = 80
}

variable "memory_threshold" {
  description = "Memory utilization threshold for Redis alarm"
  type        = number
  default     = 85
}

variable "connections_threshold" {
  description = "Connections threshold for Redis alarm"
  type        = number
  default     = 1000
}

variable "cache_hit_rate_threshold" {
  description = "Cache hit rate threshold for Redis alarm"
  type        = number
  default     = 80
}

# Alarm evaluation settings
variable "alarm_evaluation_periods" {
  description = "Number of periods over which data is compared to the specified threshold"
  type        = number
  default     = 2
}

variable "alarm_period" {
  description = "The period in seconds over which the specified statistic is applied"
  type        = number
  default     = 300
}