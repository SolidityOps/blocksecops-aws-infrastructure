# EKS Managed Node Groups Configuration
# This configuration creates managed node groups with autoscaling capabilities
# for both staging and production environments

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = var.node_group_name
  node_role_arn   = aws_iam_role.node_group.arn
  subnet_ids      = var.node_group_subnet_ids

  instance_types = var.node_group_instance_types
  capacity_type  = var.node_group_capacity_type
  disk_size      = var.node_group_disk_size

  scaling_config {
    desired_size = var.node_group_desired_size
    max_size     = var.node_group_max_size
    min_size     = var.node_group_min_size
  }

  update_config {
    max_unavailable_percentage = var.node_group_max_unavailable_percentage
  }

  ami_type        = var.node_group_ami_type
  release_version = var.node_group_release_version

  remote_access {
    ec2_ssh_key               = var.node_group_ssh_key
    source_security_group_ids = var.node_group_ssh_security_groups
  }

  labels = var.node_group_labels

  taint {
    key    = var.node_group_taint_key
    value  = var.node_group_taint_value
    effect = var.node_group_taint_effect
  }

  depends_on = [
    aws_iam_role_policy_attachment.node_group_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node_group_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node_group_AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.node_group_AmazonEKSClusterAutoscalerPolicy,
  ]

  tags = merge(var.tags, {
    Name                                                 = "${var.cluster_name}-${var.node_group_name}"
    Type                                                 = "EKS-NodeGroup"
    "kubernetes.io/cluster/${aws_eks_cluster.main.name}" = "owned"
  })

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
}

# IAM Role for EKS Node Group
resource "aws_iam_role" "node_group" {
  name = "${var.cluster_name}-${var.node_group_name}-role"

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

  tags = var.tags
}

# Required IAM Policy Attachments for Node Group
resource "aws_iam_role_policy_attachment" "node_group_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node_group.name
}

resource "aws_iam_role_policy_attachment" "node_group_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node_group.name
}

resource "aws_iam_role_policy_attachment" "node_group_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node_group.name
}

# IAM Policy for Cluster Autoscaler
resource "aws_iam_policy" "cluster_autoscaler" {
  name        = "${var.cluster_name}-cluster-autoscaler-policy"
  description = "Policy for EKS Cluster Autoscaler"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeScalingActivities",
          "autoscaling:DescribeTags",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeLaunchTemplateVersions"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup",
          "ec2:DescribeImages",
          "ec2:GetInstanceTypesFromInstanceRequirements",
          "eks:DescribeNodegroup"
        ]
        Resource = "*"
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "node_group_AmazonEKSClusterAutoscalerPolicy" {
  policy_arn = aws_iam_policy.cluster_autoscaler.arn
  role       = aws_iam_role.node_group.name
}

# Launch Template for Node Group (optional advanced configuration)
resource "aws_launch_template" "node_group" {
  count = var.use_launch_template ? 1 : 0

  name_prefix = "${var.cluster_name}-${var.node_group_name}-"

  vpc_security_group_ids = [aws_security_group.node_group.id]

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    cluster_name = aws_eks_cluster.main.name
    endpoint     = aws_eks_cluster.main.endpoint
    ca_data      = aws_eks_cluster.main.certificate_authority[0].data
  }))

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, {
      Name = "${var.cluster_name}-${var.node_group_name}-node"
      Type = "EKS-Node"
    })
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Additional Node Group for Multi-AZ deployment
resource "aws_eks_node_group" "secondary" {
  count = var.create_secondary_node_group ? 1 : 0

  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.node_group_name}-secondary"
  node_role_arn   = aws_iam_role.node_group.arn
  subnet_ids      = var.secondary_node_group_subnet_ids

  instance_types = var.secondary_node_group_instance_types
  capacity_type  = var.secondary_node_group_capacity_type
  disk_size      = var.secondary_node_group_disk_size

  scaling_config {
    desired_size = var.secondary_node_group_desired_size
    max_size     = var.secondary_node_group_max_size
    min_size     = var.secondary_node_group_min_size
  }

  update_config {
    max_unavailable_percentage = var.secondary_node_group_max_unavailable_percentage
  }

  ami_type = var.secondary_node_group_ami_type

  labels = var.secondary_node_group_labels

  depends_on = [
    aws_iam_role_policy_attachment.node_group_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node_group_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node_group_AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.node_group_AmazonEKSClusterAutoscalerPolicy,
  ]

  tags = merge(var.tags, {
    Name                                                 = "${var.cluster_name}-${var.node_group_name}-secondary"
    Type                                                 = "EKS-NodeGroup-Secondary"
    "kubernetes.io/cluster/${aws_eks_cluster.main.name}" = "owned"
  })

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
}