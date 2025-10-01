# EKS Node Groups Configuration

# Launch template for managed node groups
resource "aws_launch_template" "node_group" {
  for_each = var.node_groups

  name_prefix   = "${local.name_prefix}-${each.key}-"
  image_id      = data.aws_ssm_parameter.eks_optimized_ami.value
  instance_type = each.value.instance_types[0]

  vpc_security_group_ids = var.node_security_group_ids

  # User data for EKS bootstrap
  user_data = base64encode(templatefile("${path.module}/templates/userdata.sh", {
    cluster_name        = aws_eks_cluster.main.name
    bootstrap_arguments = lookup(each.value, "bootstrap_extra_args", "")
  }))

  # Block device mappings
  dynamic "block_device_mappings" {
    for_each = lookup(each.value, "block_device_mappings", [])
    content {
      device_name = block_device_mappings.value.device_name
      ebs {
        volume_size           = lookup(block_device_mappings.value, "volume_size", 50)
        volume_type           = lookup(block_device_mappings.value, "volume_type", "gp3")
        encrypted             = lookup(block_device_mappings.value, "encrypted", true)
        kms_key_id            = var.enable_encryption ? aws_kms_key.eks[0].arn : null
        delete_on_termination = true
      }
    }
  }

  # Default block device mapping if none specified
  dynamic "block_device_mappings" {
    for_each = length(lookup(each.value, "block_device_mappings", [])) == 0 ? [1] : []
    content {
      device_name = "/dev/xvda"
      ebs {
        volume_size           = lookup(each.value, "disk_size", 50)
        volume_type           = "gp3"
        encrypted             = true
        kms_key_id            = var.enable_encryption ? aws_kms_key.eks[0].arn : null
        delete_on_termination = true
      }
    }
  }

  # Instance metadata options
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
    instance_metadata_tags      = "enabled"
  }

  # Monitoring
  monitoring {
    enabled = lookup(each.value, "enable_monitoring", true)
  }

  # Network interfaces
  network_interfaces {
    associate_public_ip_address = false
    delete_on_termination       = true
    security_groups             = var.node_security_group_ids
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(local.common_tags, {
      Name      = "${local.name_prefix}-${each.key}-node"
      NodeGroup = each.key
    })
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(local.common_tags, {
      Name      = "${local.name_prefix}-${each.key}-volume"
      NodeGroup = each.key
    })
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-${each.key}-launch-template"
    Type = "launch-template"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# EKS Managed Node Groups
resource "aws_eks_node_group" "main" {
  for_each = var.node_groups

  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${local.name_prefix}-${each.key}"
  node_role_arn   = aws_iam_role.node_group.arn
  subnet_ids      = var.node_group_subnet_ids

  # Instance configuration
  instance_types = each.value.instance_types
  ami_type       = lookup(each.value, "ami_type", "AL2_x86_64")
  capacity_type  = lookup(each.value, "capacity_type", "ON_DEMAND")
  disk_size      = lookup(each.value, "disk_size", 50)

  # Scaling configuration
  scaling_config {
    desired_size = each.value.desired_size
    max_size     = each.value.max_size
    min_size     = each.value.min_size
  }

  # Update configuration
  update_config {
    max_unavailable_percentage = lookup(each.value, "max_unavailable_percentage", 25)
  }

  # Launch template
  launch_template {
    id      = aws_launch_template.node_group[each.key].id
    version = aws_launch_template.node_group[each.key].latest_version
  }

  # Labels
  labels = merge(
    {
      "node-group"  = each.key
      "environment" = var.environment
    },
    lookup(each.value, "k8s_labels", {})
  )

  # Taints
  dynamic "taint" {
    for_each = lookup(each.value, "k8s_taints", [])
    content {
      key    = taint.value.key
      value  = taint.value.value
      effect = taint.value.effect
    }
  }

  tags = merge(local.cluster_tags, {
    Name      = "${local.name_prefix}-${each.key}"
    Type      = "eks-node-group"
    NodeGroup = each.key
  })

  depends_on = [
    aws_iam_role_policy_attachment.node_group_amazon_eks_worker_node_policy,
    aws_iam_role_policy_attachment.node_group_amazon_eks_cni_policy,
    aws_iam_role_policy_attachment.node_group_amazon_ec2_container_registry_read_only,
    aws_iam_role_policy_attachment.node_group_amazon_ebs_csi_driver_policy,
    aws_eks_cluster.main
  ]

  lifecycle {
    ignore_changes = [
      # Ignore scaling changes if managed by cluster autoscaler
      scaling_config[0].desired_size
    ]
  }
}

# Auto Scaling Group tags for cluster autoscaler
resource "aws_autoscaling_group_tag" "cluster_autoscaler" {
  for_each = {
    for ng_name, ng_config in var.node_groups : ng_name => ng_config
    if lookup(ng_config, "enable_cluster_autoscaler", true)
  }

  autoscaling_group_name = aws_eks_node_group.main[each.key].resources[0].autoscaling_groups[0].name

  tag {
    key                 = "k8s.io/cluster-autoscaler/${aws_eks_cluster.main.name}"
    value               = "owned"
    propagate_at_launch = false
  }
}

resource "aws_autoscaling_group_tag" "cluster_autoscaler_enabled" {
  for_each = {
    for ng_name, ng_config in var.node_groups : ng_name => ng_config
    if lookup(ng_config, "enable_cluster_autoscaler", true)
  }

  autoscaling_group_name = aws_eks_node_group.main[each.key].resources[0].autoscaling_groups[0].name

  tag {
    key                 = "k8s.io/cluster-autoscaler/enabled"
    value               = "true"
    propagate_at_launch = false
  }
}