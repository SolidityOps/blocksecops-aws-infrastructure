# Staging Environment Variables

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "solidity-security"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "staging"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

# Network Configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.1.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

# EKS Configuration
variable "cluster_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
  default     = "1.27"
}

variable "node_instance_types" {
  description = "EC2 instance types for EKS worker nodes"
  type        = list(string)
  default     = ["t3.large"]
}

variable "node_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 3
}

variable "node_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 8
}

# RDS Configuration
variable "rds_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.small"
}

variable "rds_allocated_storage" {
  description = "RDS allocated storage in GB"
  type        = number
  default     = 100
}

variable "rds_max_allocated_storage" {
  description = "RDS maximum allocated storage in GB for autoscaling"
  type        = number
  default     = 500
}

variable "database_name" {
  description = "Name of the database"
  type        = string
  default     = "solidity_security_staging"
}

variable "database_username" {
  description = "Database username"
  type        = string
  default     = "postgres"
}

# ElastiCache Configuration
variable "elasticache_node_type" {
  description = "ElastiCache node type"
  type        = string
  default     = "cache.t3.small"
}

variable "elasticache_num_nodes" {
  description = "Number of ElastiCache nodes"
  type        = number
  default     = 2
}

variable "elasticache_parameter_group" {
  description = "ElastiCache parameter group"
  type        = string
  default     = "default.redis7"
}

variable "elasticache_engine_version" {
  description = "ElastiCache engine version"
  type        = string
  default     = "7.0"
}

# ECR Configuration
variable "ecr_repositories" {
  description = "List of ECR repositories to create"
  type        = list(string)
  default = [
    "api-service",
    "tool-integration-service",
    "orchestration-service",
    "intelligence-engine-service",
    "data-service",
    "notification-service"
  ]
}

# Service Accounts Configuration
variable "service_accounts" {
  description = "Service accounts that need IAM roles"
  type = map(object({
    namespace            = string
    service_account_name = string
    policy_arns          = list(string)
    custom_policy        = optional(string)
  }))
  default = {
    api_service = {
      namespace            = "default"
      service_account_name = "api-service"
      policy_arns         = ["arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"]
      custom_policy       = null
    }
    data_service = {
      namespace            = "default"
      service_account_name = "data-service"
      policy_arns         = [
        "arn:aws:iam::aws:policy/AmazonS3FullAccess",
        "arn:aws:iam::aws:policy/AmazonRDSDataFullAccess"
      ]
      custom_policy = null
    }
    orchestration_service = {
      namespace            = "default"
      service_account_name = "orchestration-service"
      policy_arns         = ["arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"]
      custom_policy       = null
    }
  }
}