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

# Monitoring Module
module "monitoring" {
  source = "../../modules/monitoring"

  environment         = "production"
  aws_region         = var.aws_region
  vpc_id             = module.networking.vpc_id
  log_retention_days = var.log_retention_days
  common_tags        = var.common_tags
}