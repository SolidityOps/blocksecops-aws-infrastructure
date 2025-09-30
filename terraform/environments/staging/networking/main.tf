# Staging environment networking configuration
# Single-AZ deployment for cost optimization

terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    # Backend configuration will be provided via backend config file
    # terraform init -backend-config=backend.tfvars
  }
}

# Configure AWS Provider
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = "staging"
      ManagedBy   = "terraform"
      Service     = "networking"
      Owner       = "devops"
      Project     = "solidity-security"
      CostCenter  = "engineering"
      Terraform   = "true"
    }
  }
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Local values
locals {
  environment = "staging"
  region      = data.aws_region.current.name
  account_id  = data.aws_caller_identity.current.account_id

  common_tags = {
    Environment   = local.environment
    Region        = local.region
    AccountId     = local.account_id
    DeployedBy    = "terraform"
    LastUpdated   = timestamp()
    BackupPolicy  = "daily"
    Schedule      = "business-hours"
    CostOptimized = "true"
  }
}

# Networking module
module "networking" {
  source = "../../../modules/networking"

  project     = var.project
  environment = local.environment
  vpc_cidr    = var.vpc_cidr

  # Single-AZ deployment for staging cost optimization
  single_az_deployment = var.single_az_deployment
  max_azs              = 1

  # NAT configuration - use NAT instance for cost savings in staging
  enable_nat_gateway = var.enable_nat_gateway
  use_nat_instance   = var.use_nat_instance
  nat_instance_type  = var.nat_instance_type

  # Subnet configuration
  create_database_subnets        = var.create_database_subnets
  database_subnet_internet_access = false

  # Security groups
  create_eks_security_groups      = var.create_eks_security_groups
  create_alb_security_group      = var.create_alb_security_group
  create_database_security_groups = var.create_database_security_groups
  create_bastion_security_group  = var.create_bastion_security_group

  # VPC endpoints - minimal for staging
  create_vpc_endpoints = var.create_vpc_endpoints

  # Network ACLs
  create_network_acls = var.create_network_acls

  # Monitoring
  enable_vpc_flow_logs      = var.enable_vpc_flow_logs
  flow_logs_retention_days  = var.flow_logs_retention_days

  tags = merge(local.common_tags, var.additional_tags)
}