# EKS Cluster Configuration

# EKS Cluster
resource "aws_eks_cluster" "main" {
  name     = "${local.name_prefix}-eks"
  role_arn = aws_iam_role.cluster.arn
  version  = var.cluster_version

  vpc_config {
    subnet_ids              = var.cluster_subnet_ids
    endpoint_private_access = var.cluster_endpoint_private_access
    endpoint_public_access  = var.cluster_endpoint_public_access
    public_access_cidrs     = var.cluster_endpoint_public_access_cidrs
    security_group_ids      = var.cluster_security_group_ids
  }

  # Enable cluster logging
  enabled_cluster_log_types = var.cluster_enabled_log_types

  # Encryption configuration
  dynamic "encryption_config" {
    for_each = var.enable_encryption ? [1] : []
    content {
      provider {
        key_arn = aws_kms_key.eks[0].arn
      }
      resources = ["secrets"]
    }
  }

  # Network configuration
  kubernetes_network_config {
    service_ipv4_cidr = var.cluster_service_ipv4_cidr
    ip_family         = "ipv4"
  }

  # Add-on configuration
  dynamic "access_config" {
    for_each = var.cluster_authentication_mode != null ? [1] : []
    content {
      authentication_mode                         = var.cluster_authentication_mode
      bootstrap_cluster_creator_admin_permissions = var.bootstrap_cluster_creator_admin_permissions
    }
  }

  tags = merge(local.cluster_tags, {
    Name = "${local.name_prefix}-eks"
    Type = "eks-cluster"
  })

  depends_on = [
    aws_iam_role_policy_attachment.cluster_amazon_eks_cluster_policy,
    aws_iam_role_policy_attachment.cluster_amazon_eks_vpc_resource_controller,
    aws_cloudwatch_log_group.eks_cluster
  ]

  lifecycle {
    ignore_changes = [
      # Ignore changes to access_config as it may be managed by other tools
      access_config
    ]
  }
}

# EKS OIDC Identity Provider
resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-eks-oidc"
    Type = "oidc-provider"
  })
}

# Get OIDC thumbprint
data "tls_certificate" "eks" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

# Security group for additional EKS cluster rules
resource "aws_security_group" "cluster_additional" {
  count = var.create_cluster_security_group ? 1 : 0

  name        = "${local.name_prefix}-eks-cluster-additional"
  description = "Additional security group for EKS cluster"
  vpc_id      = var.vpc_id

  # Allow HTTPS from private subnets to cluster
  ingress {
    description = "HTTPS from private subnets"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.private_subnet_cidrs
  }

  # Allow all outbound traffic
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-eks-cluster-additional"
    Type = "security-group"
  })
}

# EKS Cluster Authentication
resource "aws_eks_access_policy_association" "admin" {
  count = var.enable_cluster_admin_access ? 1 : 0

  cluster_name  = aws_eks_cluster.main.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"

  access_scope {
    type = "cluster"
  }

  depends_on = [
    aws_eks_cluster.main
  ]
}