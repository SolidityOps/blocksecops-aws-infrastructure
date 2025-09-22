# Production Environment Variables

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "solidity-security"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
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
  default     = "10.0.0.0/16"
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

# General Node Group Configuration
variable "node_instance_types" {
  description = "EC2 instance types for EKS worker nodes"
  type        = list(string)
  default     = ["m5.xlarge", "m5.2xlarge"]
}

variable "node_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 6
}

variable "node_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 3
}

variable "node_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 15
}

# Spot Node Group Configuration
variable "spot_node_instance_types" {
  description = "EC2 instance types for EKS spot worker nodes"
  type        = list(string)
  default     = ["m5.large", "m5.xlarge", "c5.large", "c5.xlarge"]
}

variable "spot_node_desired_size" {
  description = "Desired number of spot worker nodes"
  type        = number
  default     = 3
}

variable "spot_node_min_size" {
  description = "Minimum number of spot worker nodes"
  type        = number
  default     = 0
}

variable "spot_node_max_size" {
  description = "Maximum number of spot worker nodes"
  type        = number
  default     = 10
}

# RDS Configuration
variable "rds_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.r5.xlarge"
}

variable "rds_allocated_storage" {
  description = "RDS allocated storage in GB"
  type        = number
  default     = 500
}

variable "rds_max_allocated_storage" {
  description = "RDS maximum allocated storage in GB for autoscaling"
  type        = number
  default     = 2000
}

variable "database_name" {
  description = "Name of the database"
  type        = string
  default     = "solidity_security_prod"
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
  default     = "cache.r5.xlarge"
}

variable "elasticache_num_nodes" {
  description = "Number of ElastiCache nodes"
  type        = number
  default     = 3
}

variable "elasticache_parameter_group" {
  description = "ElastiCache parameter group"
  type        = string
  default     = "default.redis7.cluster.on"
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
    "notification-service",
    "web-ui",
    "monitoring-service"
  ]
}

variable "ecr_replication_destinations" {
  description = "List of regions for ECR cross-region replication"
  type        = list(string)
  default     = ["us-west-2"]
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
      policy_arns         = [
        "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess",
        "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
      ]
      custom_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Action = [
              "secretsmanager:GetSecretValue",
              "secretsmanager:DescribeSecret"
            ]
            Resource = "arn:aws:secretsmanager:*:*:secret:solidity-security-production/*"
          }
        ]
      })
    }
    data_service = {
      namespace            = "default"
      service_account_name = "data-service"
      policy_arns         = [
        "arn:aws:iam::aws:policy/AmazonS3FullAccess",
        "arn:aws:iam::aws:policy/AmazonRDSDataFullAccess",
        "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
      ]
      custom_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Action = [
              "secretsmanager:GetSecretValue",
              "secretsmanager:DescribeSecret"
            ]
            Resource = "arn:aws:secretsmanager:*:*:secret:solidity-security-production/*"
          }
        ]
      })
    }
    orchestration_service = {
      namespace            = "default"
      service_account_name = "orchestration-service"
      policy_arns         = [
        "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
        "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
      ]
      custom_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Action = [
              "eks:DescribeCluster",
              "eks:ListClusters"
            ]
            Resource = "*"
          }
        ]
      })
    }
    intelligence_engine = {
      namespace            = "default"
      service_account_name = "intelligence-engine-service"
      policy_arns         = [
        "arn:aws:iam::aws:policy/AmazonS3FullAccess",
        "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
      ]
      custom_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Action = [
              "secretsmanager:GetSecretValue",
              "secretsmanager:DescribeSecret"
            ]
            Resource = "arn:aws:secretsmanager:*:*:secret:solidity-security-production/*"
          }
        ]
      })
    }
    notification_service = {
      namespace            = "default"
      service_account_name = "notification-service"
      policy_arns         = [
        "arn:aws:iam::aws:policy/AmazonSESFullAccess",
        "arn:aws:iam::aws:policy/AmazonSNSFullAccess",
        "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
      ]
      custom_policy = null
    }
    monitoring_service = {
      namespace            = "monitoring"
      service_account_name = "monitoring-service"
      policy_arns         = [
        "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy",
        "arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess"
      ]
      custom_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Action = [
              "logs:CreateLogGroup",
              "logs:CreateLogStream",
              "logs:PutLogEvents",
              "logs:DescribeLogStreams",
              "logs:DescribeLogGroups"
            ]
            Resource = "*"
          }
        ]
      })
    }
  }
}