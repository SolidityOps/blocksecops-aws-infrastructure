# Production Environment Configuration for Solidity Security Platform
# Single-AZ deployment for MVP cost optimization

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = "production"
      Project     = "SoliditySecurityPlatform"
      ManagedBy   = "Terraform"
      Owner       = "DevOps"
    }
  }
}

# Networking Module
module "networking" {
  source = "../../modules/networking"

  environment           = "production"
  aws_region           = var.aws_region
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidr   = var.public_subnet_cidr
  private_subnet_cidr  = var.private_subnet_cidr
  common_tags          = var.common_tags
}

# Storage Module (ElastiCache Redis)
module "storage" {
  source = "../../modules/storage"

  environment             = "production"
  vpc_id                 = module.networking.vpc_id
  private_subnet_ids     = [module.networking.private_subnet_id]
  eks_security_group_id  = module.networking.eks_nodes_security_group_id
  redis_node_type        = var.redis_node_type
  redis_num_cache_nodes  = var.redis_num_cache_nodes
  backup_retention_limit = var.backup_retention_limit
  backup_window         = var.backup_window
  maintenance_window    = var.maintenance_window
  snapshot_window       = var.snapshot_window
  tags                  = var.common_tags
}

# Cache Monitoring Module
module "cache_monitoring" {
  source = "../../modules/monitoring"

  environment       = "production"
  redis_cluster_id = module.storage.redis_cluster_id
  tags             = var.common_tags
}

# Monitoring Module
module "monitoring" {
  source = "../../modules/monitoring"

  environment         = "production"
  aws_region         = var.aws_region
  vpc_id             = module.networking.vpc_id
  log_retention_days = var.log_retention_days
  common_tags        = var.common_tags
}