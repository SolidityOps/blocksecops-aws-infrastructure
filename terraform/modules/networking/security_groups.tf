# Security Groups for Task 1.2
# Least-privilege access for EKS, databases, and ElastiCache

# Security Group for EKS Cluster Control Plane
resource "aws_security_group" "eks_cluster" {
  count = var.create_eks_security_groups ? 1 : 0

  name_prefix = "${local.name_prefix}-eks-cluster-"
  vpc_id      = aws_vpc.main.id
  description = "Security group for EKS cluster control plane"

  # HTTPS access from worker nodes
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "HTTPS access from VPC"
  }

  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-eks-cluster-sg"
    Type = "security-group"
    Role = "eks-cluster"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Security Group for EKS Worker Nodes
resource "aws_security_group" "eks_nodes" {
  count = var.create_eks_security_groups ? 1 : 0

  name_prefix = "${local.name_prefix}-eks-nodes-"
  vpc_id      = aws_vpc.main.id
  description = "Security group for EKS worker nodes"

  # Self-referencing rule for node-to-node communication
  ingress {
    from_port = 0
    to_port   = 65535
    protocol  = "tcp"
    self      = true
    description = "Node-to-node communication"
  }

  # HTTPS access to cluster API
  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = var.create_eks_security_groups ? [aws_security_group.eks_cluster[0].id] : []
    description     = "HTTPS access from EKS cluster"
  }

  # Kubelet API access
  ingress {
    from_port = 10250
    to_port   = 10250
    protocol  = "tcp"
    self      = true
    description = "Kubelet API"
  }

  # NodePort services
  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "NodePort services"
  }

  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-eks-nodes-sg"
    Type = "security-group"
    Role = "eks-nodes"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Security Group for Application Load Balancer
resource "aws_security_group" "alb" {
  count = var.create_alb_security_group ? 1 : 0

  name_prefix = "${local.name_prefix}-alb-"
  vpc_id      = aws_vpc.main.id
  description = "Security group for Application Load Balancer"

  # HTTP access from internet
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP access from internet"
  }

  # HTTPS access from internet
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS access from internet"
  }

  # All outbound traffic to VPC
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
    description = "All outbound traffic to VPC"
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-alb-sg"
    Type = "security-group"
    Role = "alb"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Security Group for PostgreSQL Database (will be used by Kubernetes NetworkPolicies)
resource "aws_security_group" "postgresql" {
  count = var.create_database_security_groups ? 1 : 0

  name_prefix = "${local.name_prefix}-postgresql-"
  vpc_id      = aws_vpc.main.id
  description = "Security group for PostgreSQL database access"

  # PostgreSQL access from EKS nodes and application services
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = var.create_eks_security_groups ? [aws_security_group.eks_nodes[0].id] : []
    description     = "PostgreSQL access from EKS nodes"
  }

  # PostgreSQL access from private subnets (for administrative access)
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = aws_subnet.private[*].cidr_block
    description = "PostgreSQL access from private subnets"
  }

  # No outbound rules needed for database security group

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-postgresql-sg"
    Type = "security-group"
    Role = "postgresql"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Security Group for ElastiCache Redis
resource "aws_security_group" "elasticache" {
  count = var.create_database_security_groups ? 1 : 0

  name_prefix = "${local.name_prefix}-elasticache-"
  vpc_id      = aws_vpc.main.id
  description = "Security group for ElastiCache Redis access"

  # Redis access from EKS nodes and application services
  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = var.create_eks_security_groups ? [aws_security_group.eks_nodes[0].id] : []
    description     = "Redis access from EKS nodes"
  }

  # Redis access from private subnets
  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = aws_subnet.private[*].cidr_block
    description = "Redis access from private subnets"
  }

  # No outbound rules needed for cache security group

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-elasticache-sg"
    Type = "security-group"
    Role = "elasticache"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Security Group for VPC Endpoints
resource "aws_security_group" "vpc_endpoints" {
  count = var.create_vpc_endpoints ? 1 : 0

  name_prefix = "${local.name_prefix}-vpc-endpoints-"
  vpc_id      = aws_vpc.main.id
  description = "Security group for VPC endpoints"

  # HTTPS access from VPC
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "HTTPS access from VPC"
  }

  # DNS access from VPC
  ingress {
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "DNS TCP access from VPC"
  }

  ingress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = [var.vpc_cidr]
    description = "DNS UDP access from VPC"
  }

  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-vpc-endpoints-sg"
    Type = "security-group"
    Role = "vpc-endpoints"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Security Group for Bastion Host (optional)
resource "aws_security_group" "bastion" {
  count = var.create_bastion_security_group ? 1 : 0

  name_prefix = "${local.name_prefix}-bastion-"
  vpc_id      = aws_vpc.main.id
  description = "Security group for bastion host"

  # SSH access from specific IP ranges
  dynamic "ingress" {
    for_each = var.bastion_allowed_cidr_blocks
    content {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
      description = "SSH access from allowed CIDR block"
    }
  }

  # All outbound traffic to VPC
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
    description = "All outbound traffic to VPC"
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-bastion-sg"
    Type = "security-group"
    Role = "bastion"
  })

  lifecycle {
    create_before_destroy = true
  }
}