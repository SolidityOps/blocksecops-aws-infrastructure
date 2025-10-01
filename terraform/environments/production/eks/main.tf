# Production environment EKS configuration
# High-availability and performance optimized deployment

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
      Service     = "eks"
      Owner       = "devops"
      Project     = "solidity-security"
      CostCenter  = "production"
      Terraform   = "true"
      Compliance  = "required"
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
    BackupPolicy     = "daily"
    Schedule         = "24x7"
    HighAvailability = "true"
    Compliance       = "required"
    DataClass        = "sensitive"
  }
}

# Get networking outputs from remote state
data "terraform_remote_state" "networking" {
  backend = "s3"
  config = {
    bucket = var.terraform_state_bucket
    key    = "environments/production/networking/terraform.tfstate"
    region = var.aws_region
  }
}

# EKS module
module "eks" {
  source = "../../../modules/eks"

  project     = var.project
  environment = local.environment

  # Network configuration from networking module
  vpc_id = data.terraform_remote_state.networking.outputs.vpc_id
  cluster_subnet_ids = concat(
    data.terraform_remote_state.networking.outputs.public_subnet_ids,
    data.terraform_remote_state.networking.outputs.private_subnet_ids
  )
  node_group_subnet_ids      = data.terraform_remote_state.networking.outputs.private_subnet_ids
  cluster_security_group_ids = [data.terraform_remote_state.networking.outputs.eks_cluster_security_group_id]
  node_security_group_ids    = [data.terraform_remote_state.networking.outputs.eks_nodes_security_group_id]
  private_subnet_cidrs       = var.private_subnet_cidrs

  # Cluster configuration - production optimized
  cluster_version                      = var.cluster_version
  cluster_endpoint_private_access      = var.cluster_endpoint_private_access
  cluster_endpoint_public_access       = var.cluster_endpoint_public_access
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs
  cluster_service_ipv4_cidr            = var.cluster_service_ipv4_cidr
  cluster_enabled_log_types            = var.cluster_enabled_log_types
  cluster_authentication_mode          = var.cluster_authentication_mode

  # Node groups configuration - production optimized
  node_groups = var.node_groups

  # Security configuration - enhanced for production
  enable_encryption             = var.enable_encryption
  create_cluster_security_group = var.create_cluster_security_group
  enable_cluster_admin_access   = var.enable_cluster_admin_access

  # Add-ons configuration - comprehensive for production
  enable_coredns_addon      = var.enable_coredns_addon
  enable_kube_proxy_addon   = var.enable_kube_proxy_addon
  enable_vpc_cni_addon      = var.enable_vpc_cni_addon
  enable_ebs_csi_addon      = var.enable_ebs_csi_addon
  enable_pod_identity_addon = var.enable_pod_identity_addon

  # Service account roles
  enable_aws_load_balancer_controller = var.enable_aws_load_balancer_controller
  enable_cluster_autoscaler           = var.enable_cluster_autoscaler

  # Monitoring - comprehensive for production
  log_retention_days = var.log_retention_days

  tags = merge(local.common_tags, var.additional_tags)
}