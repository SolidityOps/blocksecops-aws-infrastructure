# Staging environment EKS configuration
# Cost-optimized deployment for development and testing

terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Temporarily disabled for permission testing
  # backend "s3" {
  #   # Backend configuration will be provided via backend config file
  #   # terraform init -backend-config=backend.tfvars
  # }
}

# Configure AWS Provider
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = "staging"
      ManagedBy   = "terraform"
      Service     = "eks"
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
    BackupPolicy  = "daily"
    Schedule      = "business-hours"
    CostOptimized = "true"
  }
}

# Mock networking data for permission testing
locals {
  mock_networking = {
    vpc_id                        = "vpc-12345678"
    public_subnet_ids             = ["subnet-11111111"]
    private_subnet_ids            = ["subnet-22222222"]
    eks_cluster_security_group_id = "sg-cluster123"
    eks_nodes_security_group_id   = "sg-nodes123"
  }
}

# EKS module
module "eks" {
  source = "../../../modules/eks"

  project     = var.project
  environment = local.environment

  # Network configuration from mock data for testing
  vpc_id = local.mock_networking.vpc_id
  cluster_subnet_ids = concat(
    local.mock_networking.public_subnet_ids,
    local.mock_networking.private_subnet_ids
  )
  node_group_subnet_ids      = local.mock_networking.private_subnet_ids
  cluster_security_group_ids = [local.mock_networking.eks_cluster_security_group_id]
  node_security_group_ids    = [local.mock_networking.eks_nodes_security_group_id]
  private_subnet_cidrs       = var.private_subnet_cidrs

  # Cluster configuration - staging optimized
  cluster_version                      = var.cluster_version
  cluster_endpoint_private_access      = var.cluster_endpoint_private_access
  cluster_endpoint_public_access       = var.cluster_endpoint_public_access
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs
  cluster_service_ipv4_cidr            = var.cluster_service_ipv4_cidr
  cluster_enabled_log_types            = var.cluster_enabled_log_types
  cluster_authentication_mode          = var.cluster_authentication_mode

  # Node groups configuration - cost optimized
  node_groups = var.node_groups

  # Security configuration
  enable_encryption             = var.enable_encryption
  create_cluster_security_group = var.create_cluster_security_group
  enable_cluster_admin_access   = var.enable_cluster_admin_access

  # Add-ons configuration - minimal for staging
  enable_coredns_addon      = var.enable_coredns_addon
  enable_kube_proxy_addon   = var.enable_kube_proxy_addon
  enable_vpc_cni_addon      = var.enable_vpc_cni_addon
  enable_ebs_csi_addon      = var.enable_ebs_csi_addon
  enable_pod_identity_addon = var.enable_pod_identity_addon

  # Service account roles
  enable_aws_load_balancer_controller = var.enable_aws_load_balancer_controller
  enable_cluster_autoscaler           = var.enable_cluster_autoscaler

  # Monitoring
  log_retention_days = var.log_retention_days

  tags = merge(local.common_tags, var.additional_tags)
}