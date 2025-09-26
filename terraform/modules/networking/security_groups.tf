# Security Groups for EKS and ElastiCache
# Configured with least-privilege access principles
# PostgreSQL runs in Kubernetes with NetworkPolicies for security

# EKS Cluster Security Group
resource "aws_security_group" "eks_cluster" {
  name        = "${var.environment}-solidity-security-eks-cluster-sg"
  description = "Security group for EKS cluster control plane"
  vpc_id      = aws_vpc.main.id

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name        = "${var.environment}-solidity-security-eks-cluster-sg"
    Environment = var.environment
    Service     = "EKS"
  })
}

# EKS Node Group Security Group
resource "aws_security_group" "eks_nodes" {
  name        = "${var.environment}-solidity-security-eks-nodes-sg"
  description = "Security group for EKS worker nodes"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Node to node communication"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    self        = true
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name        = "${var.environment}-solidity-security-eks-nodes-sg"
    Environment = var.environment
    Service     = "EKS"
  })
}

# Application Load Balancer Security Group
resource "aws_security_group" "alb" {
  name        = "${var.environment}-solidity-security-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS traffic"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name        = "${var.environment}-solidity-security-alb-sg"
    Environment = var.environment
    Service     = "ALB"
  })
}

# PostgreSQL runs as StatefulSets in Kubernetes
# Database access is controlled via Kubernetes NetworkPolicies
# No AWS security groups needed for database tier

# ElastiCache Security Group
resource "aws_security_group" "elasticache" {
  name        = "${var.environment}-solidity-security-elasticache-sg"
  description = "Security group for ElastiCache Redis cluster"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Redis access from EKS nodes only"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_nodes.id]
  }

  # ElastiCache instances do not require outbound internet connectivity
  # They only need to respond to incoming Redis connections
  # No egress rules are defined for maximum security
  # (Terraform requires at least one rule, so we use a restrictive placeholder)
  egress {
    description = "No outbound connectivity required for cache"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["127.0.0.1/32"] # Localhost only (effectively no access)
  }

  tags = merge(var.common_tags, {
    Name        = "${var.environment}-solidity-security-elasticache-sg"
    Environment = var.environment
    Service     = "ElastiCache"
  })
}

# Security Group Rules (defined separately to avoid circular dependencies)

# EKS Cluster ingress from nodes
resource "aws_security_group_rule" "eks_cluster_ingress_nodes" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.eks_nodes.id
  security_group_id        = aws_security_group.eks_cluster.id
  description              = "HTTPS from EKS nodes"
}

# EKS Nodes ingress from cluster
resource "aws_security_group_rule" "eks_nodes_ingress_cluster_pods" {
  type                     = "ingress"
  from_port                = 1025
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.eks_cluster.id
  security_group_id        = aws_security_group.eks_nodes.id
  description              = "Pod to pod communication from cluster"
}

resource "aws_security_group_rule" "eks_nodes_ingress_cluster_api" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.eks_cluster.id
  security_group_id        = aws_security_group.eks_nodes.id
  description              = "Kubernetes API access from cluster"
}

# EKS Nodes ingress from ALB for webhook
resource "aws_security_group_rule" "eks_nodes_ingress_alb_webhook" {
  type                     = "ingress"
  from_port                = 9443
  to_port                  = 9443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.eks_nodes.id
  description              = "ALB ingress controller webhooks"
}

# ALB egress to EKS nodes
resource "aws_security_group_rule" "alb_egress_eks_nodes" {
  type                     = "egress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.eks_nodes.id
  security_group_id        = aws_security_group.alb.id
  description              = "Traffic to EKS nodes"
}