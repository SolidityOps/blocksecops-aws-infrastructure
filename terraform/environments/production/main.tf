# Production Environment Configuration
# This configuration provides a production-ready environment with enhanced security, performance, and reliability

terraform {
  required_version = ">= 1.5"

  backend "s3" {
    bucket         = "solidity-security-terraform-state"
    key            = "production/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "solidity-security-terraform-locks"
  }
}

# Local variables for production environment
locals {
  project_name = var.project_name
  environment  = var.environment
  region       = var.aws_region

  # Production-specific configurations
  common_tags = {
    Project     = local.project_name
    Environment = local.environment
    ManagedBy   = "Terraform"
    Repository  = "solidity-security-aws-infrastructure"
    Owner       = "SolidityOps"
    CostCenter  = "Production"
    Backup      = "Required"
    Monitoring  = "Critical"
  }
}

# VPC Module
module "vpc" {
  source = "../../modules/vpc"

  project_name = local.project_name
  environment  = local.environment

  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  enable_nat_gateway   = true
  enable_vpn_gateway   = false
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = local.common_tags
}

# Security Groups Module
module "security_groups" {
  source = "../../modules/security-groups"

  project_name = local.project_name
  environment  = local.environment
  vpc_id       = module.vpc.vpc_id
  vpc_cidr     = var.vpc_cidr

  tags = local.common_tags
}

# EKS Module
module "eks" {
  source = "../../modules/eks"

  project_name = local.project_name
  environment  = local.environment

  vpc_id                    = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnet_ids
  control_plane_subnet_ids = module.vpc.private_subnet_ids

  cluster_version = var.cluster_version

  # Node group configuration - production environment with multiple node groups
  node_groups = {
    general = {
      desired_size    = var.node_desired_size
      max_size       = var.node_max_size
      min_size       = var.node_min_size
      instance_types = var.node_instance_types
      capacity_type  = "ON_DEMAND"

      k8s_labels = {
        Environment = local.environment
        NodeGroup  = "general"
      }

      k8s_taints = []
    }

    # Spot instances for cost optimization on non-critical workloads
    spot = {
      desired_size    = var.spot_node_desired_size
      max_size       = var.spot_node_max_size
      min_size       = var.spot_node_min_size
      instance_types = var.spot_node_instance_types
      capacity_type  = "SPOT"

      k8s_labels = {
        Environment = local.environment
        NodeGroup  = "spot"
        Workload   = "batch"
      }

      k8s_taints = [
        {
          key    = "spot-instance"
          value  = "true"
          effect = "NO_SCHEDULE"
        }
      ]
    }
  }

  # Full logging for production
  cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  # Security group IDs
  additional_security_group_ids = [
    module.security_groups.eks_cluster_security_group_id,
    module.security_groups.eks_node_security_group_id
  ]

  tags = local.common_tags
}

# IAM Module
module "iam" {
  source = "../../modules/iam"

  project_name      = local.project_name
  environment       = local.environment
  cluster_name      = module.eks.cluster_name
  oidc_provider_arn = module.eks.oidc_provider_arn

  # Application service accounts for production
  service_accounts = var.service_accounts

  # Production IAM configurations
  enable_cluster_autoscaler_role = true

  tags = local.common_tags
}

# RDS Module - Production with Multi-AZ and Read Replicas
module "rds" {
  source = "../../modules/rds"

  project_name = local.project_name
  environment  = local.environment

  vpc_id               = module.vpc.vpc_id
  db_subnet_group_name = module.vpc.database_subnet_group_name

  # Production database configuration
  instance_class    = var.rds_instance_class
  allocated_storage = var.rds_allocated_storage
  max_allocated_storage = var.rds_max_allocated_storage

  database_name = var.database_name
  username      = var.database_username

  # Production-grade configuration
  multi_az               = true
  backup_retention_period = 30
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"
  deletion_protection    = true

  # Security
  security_group_ids = [module.security_groups.rds_security_group_id]

  # Enhanced monitoring for production
  performance_insights_enabled = true
  performance_insights_retention_period = 7
  monitoring_interval         = 15

  # Enhanced backup
  copy_tags_to_snapshot = true
  skip_final_snapshot  = false
  final_snapshot_identifier = "${local.project_name}-${local.environment}-final-snapshot"

  tags = local.common_tags
}

# ElastiCache Module - Production with Redis Cluster
module "elasticache" {
  source = "../../modules/elasticache"

  project_name = local.project_name
  environment  = local.environment

  vpc_id                = module.vpc.vpc_id
  cache_subnet_group_name = module.vpc.elasticache_subnet_group_name

  # Production cache configuration with clustering
  node_type         = var.elasticache_node_type
  num_cache_nodes   = var.elasticache_num_nodes
  parameter_group_name = var.elasticache_parameter_group
  engine_version    = var.elasticache_engine_version

  # Production-specific settings
  automatic_failover_enabled = true
  multi_az_enabled          = true

  # Security
  security_group_ids = [module.security_groups.elasticache_security_group_id]

  tags = local.common_tags
}

# ECR Module
module "ecr" {
  source = "../../modules/ecr"

  project_name = local.project_name
  environment  = local.environment

  repositories = var.ecr_repositories

  # Production lifecycle policies
  enable_lifecycle_policy = true
  lifecycle_policy = {
    untagged_image_expiration_days = 14
    tagged_image_count_limit      = 20
  }

  # Enhanced security scanning
  image_scanning_configuration = {
    scan_on_push = true
  }

  # Cross-region replication for production
  enable_cross_region_replication = true
  replication_destinations = var.ecr_replication_destinations

  tags = local.common_tags
}

# Secrets Manager Module
module "secrets_manager" {
  source = "../../modules/secrets-manager"

  project_name = local.project_name
  environment  = local.environment

  # Database secrets
  database_credentials = {
    username = var.database_username
    password = module.rds.db_password
    endpoint = module.rds.db_endpoint
    port     = module.rds.db_port
  }

  # ElastiCache secrets
  elasticache_auth_token = module.elasticache.auth_token

  # Production-specific secret rotation
  enable_automatic_rotation = true
  rotation_interval_days   = 30

  tags = local.common_tags
}