# Development Environment - Main Terraform Configuration

terraform {
  required_version = ">= 1.5"

  backend "s3" {
    bucket         = "solidity-security-terraform-state-dev"
    key            = "infrastructure/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "solidity-security-terraform-locks-dev"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

# Provider configuration
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
      Owner       = "platform-team"
      CostCenter  = "development"
    }
  }
}

# Local values
locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    CreatedBy   = "terraform"
  }

  # Availability zones
  azs = slice(data.aws_availability_zones.available.names, 0, 3)
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

# KMS Key for encryption
resource "aws_kms_key" "main" {
  description             = "KMS key for ${var.project_name} ${var.environment} encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow EKS Service"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Resource = "*"
      },
      {
        Sid    = "Allow RDS Service"
        Effect = "Allow"
        Principal = {
          Service = "rds.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:Encrypt",
          "kms:GenerateDataKey*",
          "kms:ReEncrypt*"
        ]
        Resource = "*"
      },
      {
        Sid    = "Allow Secrets Manager Service"
        Effect = "Allow"
        Principal = {
          Service = "secretsmanager.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:Encrypt",
          "kms:GenerateDataKey*",
          "kms:ReEncrypt*"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-kms-key"
  })
}

resource "aws_kms_alias" "main" {
  name          = "alias/${var.project_name}-${var.environment}"
  target_key_id = aws_kms_key.main.key_id
}

# VPC Module
module "vpc" {
  source = "../../modules/vpc"

  project_name = var.project_name
  environment  = var.environment
  vpc_cidr     = var.vpc_cidr

  public_subnet_count   = 3
  private_subnet_count  = 3
  database_subnet_count = 3

  tags = local.common_tags
}

# Security Groups Module
module "security_groups" {
  source = "../../modules/security-groups"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id
  vpc_cidr     = module.vpc.vpc_cidr

  tags = local.common_tags
}

# IAM Module
module "iam" {
  source = "../../modules/iam"

  project_name     = var.project_name
  environment      = var.environment
  cluster_name     = "${var.project_name}-${var.environment}"
  oidc_provider_arn = module.eks.oidc_provider_arn

  tags = local.common_tags
}

# EKS Module
module "eks" {
  source = "../../modules/eks"

  project_name              = var.project_name
  environment               = var.environment
  vpc_id                    = module.vpc.vpc_id
  subnet_ids                = concat(module.vpc.private_subnet_ids, module.vpc.public_subnet_ids)
  node_group_subnet_ids     = module.vpc.private_subnet_ids
  kms_key_arn              = aws_kms_key.main.arn

  # Development-specific settings
  kubernetes_version        = "1.27"
  endpoint_private_access   = true
  endpoint_public_access    = true
  public_access_cidrs       = ["0.0.0.0/0"] # Restrict this in production

  # Node group configuration for development
  node_instance_types       = ["t3.medium"]
  node_desired_size         = 2
  node_min_size            = 1
  node_max_size            = 5
  node_capacity_type       = "ON_DEMAND"

  cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  log_retention_days = 7

  tags = local.common_tags

  depends_on = [module.vpc]
}

# RDS Module
module "rds" {
  source = "../../modules/rds"

  project_name       = var.project_name
  environment        = var.environment
  subnet_ids         = module.vpc.database_subnet_ids
  security_group_ids = [module.security_groups.rds_security_group_id]
  kms_key_arn       = aws_kms_key.main.arn

  # Development-specific settings
  instance_class             = "db.t3.micro"
  allocated_storage          = 20
  max_allocated_storage      = 100
  multi_az                   = false # Single AZ for development
  backup_retention_period    = 3     # Shorter retention for development
  deletion_protection        = false # Allow deletion in development
  skip_final_snapshot        = true  # Skip final snapshot in development

  # Performance monitoring
  monitoring_interval               = 60
  performance_insights_enabled      = true
  performance_insights_retention_period = 7

  tags = local.common_tags

  depends_on = [module.vpc, module.security_groups]
}

# ElastiCache Module
module "elasticache" {
  source = "../../modules/elasticache"

  project_name       = var.project_name
  environment        = var.environment
  subnet_ids         = module.vpc.database_subnet_ids
  security_group_ids = [module.security_groups.elasticache_security_group_id]
  kms_key_arn       = aws_kms_key.main.arn

  # Development-specific settings
  node_type                    = "cache.t3.micro"
  num_cache_clusters           = 1 # Single node for development
  multi_az_enabled            = false
  automatic_failover_enabled   = false
  snapshot_retention_limit     = 3

  tags = local.common_tags

  depends_on = [module.vpc, module.security_groups]
}

# ECR Module
module "ecr" {
  source = "../../modules/ecr"

  project_name = var.project_name
  environment  = var.environment

  repositories = [
    "api-service",
    "tool-integration-service",
    "orchestration-service",
    "intelligence-engine-service",
    "data-service",
    "notification-service",
    "frontend"
  ]

  tags = local.common_tags
}

# Secrets Manager Module
module "secrets_manager" {
  source = "../../modules/secrets-manager"

  project_name = var.project_name
  environment  = var.environment
  kms_key_arn  = aws_kms_key.main.arn

  # Lambda configuration for rotation
  lambda_subnet_ids         = module.vpc.private_subnet_ids
  lambda_security_group_ids = [module.security_groups.lambda_security_group_id]

  # Development secrets configuration
  secrets = [
    {
      name        = "jwt-secret"
      path        = "api-service/jwt-secret"
      description = "JWT signing secret for API service"
      type        = "api-key"
      secret_data = {
        secret_key = "dev-jwt-secret-change-in-production"
        algorithm  = "HS256"
      }
      rotation_enabled = false
      rotation_days    = 30
    },
    {
      name        = "oauth-credentials"
      path        = "api-service/oauth-credentials"
      description = "OAuth provider credentials"
      type        = "oauth"
      secret_data = {
        github_client_id     = "dev-github-client-id"
        github_client_secret = "dev-github-client-secret"
        google_client_id     = "dev-google-client-id"
        google_client_secret = "dev-google-client-secret"
      }
      rotation_enabled = false
      rotation_days    = 90
    },
    {
      name        = "tool-credentials"
      path        = "tool-integration/credentials"
      description = "Security tool API credentials"
      type        = "api-key"
      secret_data = {
        mythx_api_key    = "dev-mythx-api-key"
        slither_config   = "dev-slither-config"
        aderyn_config    = "dev-aderyn-config"
      }
      rotation_enabled = false
      rotation_days    = 60
    },
    {
      name        = "notification-credentials"
      path        = "notification/credentials"
      description = "Notification service credentials"
      type        = "api-key"
      secret_data = {
        slack_webhook_url = "https://hooks.slack.com/dev-webhook"
        smtp_username     = "dev-smtp-user"
        smtp_password     = "dev-smtp-password"
        smtp_server       = "dev-smtp.example.com"
      }
      rotation_enabled = false
      rotation_days    = 90
    }
  ]

  # Service roles for EKS workloads
  service_roles = {
    api-service = {
      service = "eks.amazonaws.com"
      additional_policies = [
        "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
      ]
    }
    tool-integration = {
      service = "eks.amazonaws.com"
      additional_policies = [
        "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
      ]
    }
    data-service = {
      service = "eks.amazonaws.com"
      additional_policies = [
        "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
      ]
    }
  }

  tags = local.common_tags

  depends_on = [module.vpc, module.security_groups]
}