# Production environment networking configuration
# Multi-AZ deployment for high availability

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
      Environment = "production"
      ManagedBy   = "terraform"
      Service     = "networking"
      Owner       = "devops"
      Project     = "solidity-security"
      CostCenter  = "production"
      Terraform   = "true"
      Compliance  = "required"
      Backup      = "required"
    }
  }
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Local values
locals {
  environment = "production"
  region      = data.aws_region.current.name
  account_id  = data.aws_caller_identity.current.account_id

  common_tags = {
    Environment      = local.environment
    Region           = local.region
    AccountId        = local.account_id
    DeployedBy       = "terraform"
    LastUpdated      = timestamp()
    BackupPolicy     = "required"
    Schedule         = "24x7"
    HighAvailability = "true"
    Monitoring       = "enhanced"
    DataClass        = "confidential"
  }
}

# Networking module
module "networking" {
  source = "../../../modules/networking"

  project     = var.project
  environment = local.environment
  vpc_cidr    = var.vpc_cidr

  # Multi-AZ deployment for production high availability
  single_az_deployment = var.single_az_deployment
  max_azs              = var.max_azs

  # NAT configuration - use NAT gateways for production reliability
  enable_nat_gateway = var.enable_nat_gateway
  use_nat_instance   = var.use_nat_instance

  # Subnet configuration
  create_database_subnets         = var.create_database_subnets
  database_subnet_internet_access = false

  # Security groups
  create_eks_security_groups      = var.create_eks_security_groups
  create_alb_security_group       = var.create_alb_security_group
  create_database_security_groups = var.create_database_security_groups
  create_bastion_security_group   = var.create_bastion_security_group
  bastion_allowed_cidr_blocks     = var.bastion_allowed_cidr_blocks

  # VPC endpoints for production cost optimization and security
  create_vpc_endpoints = var.create_vpc_endpoints

  # Network ACLs for enhanced security
  create_network_acls = var.create_network_acls

  # Enhanced monitoring for production
  enable_vpc_flow_logs     = var.enable_vpc_flow_logs
  flow_logs_retention_days = var.flow_logs_retention_days

  tags = merge(local.common_tags, var.additional_tags)
}