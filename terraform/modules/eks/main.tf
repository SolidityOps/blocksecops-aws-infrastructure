# EKS Cluster Infrastructure Module for Task 1.5
# Provides secure, scalable Kubernetes cluster for the Solidity Security Platform

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Get the latest EKS optimized AMI
data "aws_ssm_parameter" "eks_optimized_ami" {
  name = "/aws/service/eks/optimized-ami/${var.cluster_version}/amazon-linux-2/recommended/image_id"
}

# Local values for consistent naming and tagging
locals {
  name_prefix = "${var.project}-${var.environment}"

  common_tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "terraform"
    Service     = "eks"
    Owner       = "devops"
    Project     = var.project
    Terraform   = "true"
    Module      = "eks"
  })

  # Cluster tags required for EKS
  cluster_tags = merge(local.common_tags, {
    "kubernetes.io/cluster/${local.name_prefix}-eks" = "owned"
  })
}

# KMS key for EKS cluster encryption
resource "aws_kms_key" "eks" {
  count = var.enable_encryption ? 1 : 0

  description             = "KMS key for EKS cluster encryption"
  deletion_window_in_days = var.environment == "production" ? 30 : 7

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-eks-kms"
    Type = "encryption-key"
  })
}

resource "aws_kms_alias" "eks" {
  count = var.enable_encryption ? 1 : 0

  name          = "alias/${local.name_prefix}-eks"
  target_key_id = aws_kms_key.eks[0].key_id
}

# CloudWatch Log Group for EKS cluster logging
resource "aws_cloudwatch_log_group" "eks_cluster" {
  for_each = toset(var.cluster_enabled_log_types)

  name              = "/aws/eks/${local.name_prefix}-eks/${each.value}"
  retention_in_days = var.log_retention_days

  tags = merge(local.common_tags, {
    Name    = "${local.name_prefix}-eks-${each.value}-logs"
    Type    = "cluster-logs"
    LogType = each.value
  })
}

# IAM role for EKS cluster
resource "aws_iam_role" "cluster" {
  name = "${local.name_prefix}-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

# Attach required policies to cluster role
resource "aws_iam_role_policy_attachment" "cluster_amazon_eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

# Optional: Enable Security Groups for Pods
resource "aws_iam_role_policy_attachment" "cluster_amazon_eks_vpc_resource_controller" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.cluster.name
}

# IAM role for EKS node groups
resource "aws_iam_role" "node_group" {
  name = "${local.name_prefix}-eks-node-group-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

# Attach required policies to node group role
resource "aws_iam_role_policy_attachment" "node_group_amazon_eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node_group.name
}

resource "aws_iam_role_policy_attachment" "node_group_amazon_eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node_group.name
}

resource "aws_iam_role_policy_attachment" "node_group_amazon_ec2_container_registry_read_only" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node_group.name
}

# Additional policy for EBS CSI driver
resource "aws_iam_role_policy_attachment" "node_group_amazon_ebs_csi_driver_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.node_group.name
}

# Custom policy for additional permissions
resource "aws_iam_role_policy" "node_group_additional_policy" {
  name = "${local.name_prefix}-eks-node-group-additional-policy"
  role = aws_iam_role.node_group.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath",
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = "*"
      }
    ]
  })
}