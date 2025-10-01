# EKS Module Outputs

# Cluster Information
output "cluster_id" {
  description = "EKS cluster ID"
  value       = aws_eks_cluster.main.id
}

output "cluster_arn" {
  description = "EKS cluster ARN"
  value       = aws_eks_cluster.main.arn
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_version" {
  description = "EKS cluster Kubernetes version"
  value       = aws_eks_cluster.main.version
}

output "cluster_platform_version" {
  description = "EKS cluster platform version"
  value       = aws_eks_cluster.main.platform_version
}

output "cluster_status" {
  description = "EKS cluster status"
  value       = aws_eks_cluster.main.status
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = aws_eks_cluster.main.certificate_authority[0].data
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
}

output "cluster_primary_security_group_id" {
  description = "The cluster primary security group ID created by EKS"
  value       = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
}

# OIDC Provider Information
output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster OIDC Issuer"
  value       = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC Provider for the EKS cluster"
  value       = aws_iam_openid_connect_provider.eks.arn
}

# Node Groups Information
output "node_groups" {
  description = "Map of EKS node groups"
  value = {
    for k, v in aws_eks_node_group.main : k => {
      arn            = v.arn
      status         = v.status
      capacity_type  = v.capacity_type
      instance_types = v.instance_types
      ami_type       = v.ami_type
      node_role_arn  = v.node_role_arn
      subnet_ids     = v.subnet_ids
      scaling_config = v.scaling_config
      remote_access  = v.remote_access
      labels         = v.labels
      taints         = v.taint
    }
  }
}

output "node_group_arns" {
  description = "List of EKS node group ARNs"
  value       = [for ng in aws_eks_node_group.main : ng.arn]
}

output "node_group_status" {
  description = "Status of each EKS node group"
  value       = { for k, v in aws_eks_node_group.main : k => v.status }
}

# IAM Roles
output "cluster_iam_role_arn" {
  description = "IAM role ARN of the EKS cluster"
  value       = aws_iam_role.cluster.arn
}

output "cluster_iam_role_name" {
  description = "IAM role name of the EKS cluster"
  value       = aws_iam_role.cluster.name
}

output "node_group_iam_role_arn" {
  description = "IAM role ARN of the EKS node groups"
  value       = aws_iam_role.node_group.arn
}

output "node_group_iam_role_name" {
  description = "IAM role name of the EKS node groups"
  value       = aws_iam_role.node_group.name
}

# Service Account Roles
output "aws_load_balancer_controller_role_arn" {
  description = "ARN of IAM role for AWS Load Balancer Controller"
  value       = var.enable_aws_load_balancer_controller ? aws_iam_role.aws_load_balancer_controller[0].arn : null
}

output "cluster_autoscaler_role_arn" {
  description = "ARN of IAM role for Cluster Autoscaler"
  value       = var.enable_cluster_autoscaler ? aws_iam_role.cluster_autoscaler[0].arn : null
}

output "ebs_csi_driver_role_arn" {
  description = "ARN of IAM role for EBS CSI Driver"
  value       = var.enable_ebs_csi_addon ? aws_iam_role.ebs_csi_driver[0].arn : null
}

# Add-ons Information
output "addons" {
  description = "Map of EKS add-ons"
  value = {
    coredns = var.enable_coredns_addon ? {
      arn           = aws_eks_addon.coredns[0].arn
      status        = aws_eks_addon.coredns[0].status
      addon_version = aws_eks_addon.coredns[0].addon_version
    } : null
    kube_proxy = var.enable_kube_proxy_addon ? {
      arn           = aws_eks_addon.kube_proxy[0].arn
      status        = aws_eks_addon.kube_proxy[0].status
      addon_version = aws_eks_addon.kube_proxy[0].addon_version
    } : null
    vpc_cni = var.enable_vpc_cni_addon ? {
      arn           = aws_eks_addon.vpc_cni[0].arn
      status        = aws_eks_addon.vpc_cni[0].status
      addon_version = aws_eks_addon.vpc_cni[0].addon_version
    } : null
    ebs_csi_driver = var.enable_ebs_csi_addon ? {
      arn           = aws_eks_addon.ebs_csi_driver[0].arn
      status        = aws_eks_addon.ebs_csi_driver[0].status
      addon_version = aws_eks_addon.ebs_csi_driver[0].addon_version
    } : null
    pod_identity_agent = var.enable_pod_identity_addon ? {
      arn           = aws_eks_addon.eks_pod_identity_agent[0].arn
      status        = aws_eks_addon.eks_pod_identity_agent[0].status
      addon_version = aws_eks_addon.eks_pod_identity_agent[0].addon_version
    } : null
  }
}

# Encryption
output "cluster_kms_key_id" {
  description = "KMS key ID used for EKS cluster encryption"
  value       = var.enable_encryption ? aws_kms_key.eks[0].id : null
}

output "cluster_kms_key_arn" {
  description = "KMS key ARN used for EKS cluster encryption"
  value       = var.enable_encryption ? aws_kms_key.eks[0].arn : null
}

# CloudWatch Logs
output "cloudwatch_log_groups" {
  description = "Map of CloudWatch log groups for EKS cluster logs"
  value       = { for k, v in aws_cloudwatch_log_group.eks_cluster : k => v.name }
}

# Kubeconfig Information
output "kubeconfig" {
  description = "Kubeconfig for the EKS cluster"
  value = {
    apiVersion      = "v1"
    kind            = "Config"
    current_context = aws_eks_cluster.main.name
    contexts = [{
      name = aws_eks_cluster.main.name
      context = {
        cluster = aws_eks_cluster.main.name
        user    = aws_eks_cluster.main.name
      }
    }]
    clusters = [{
      name = aws_eks_cluster.main.name
      cluster = {
        server                     = aws_eks_cluster.main.endpoint
        certificate_authority_data = aws_eks_cluster.main.certificate_authority[0].data
      }
    }]
    users = [{
      name = aws_eks_cluster.main.name
      user = {
        exec = {
          apiVersion = "client.authentication.k8s.io/v1beta1"
          command    = "aws"
          args = [
            "eks",
            "get-token",
            "--cluster-name",
            aws_eks_cluster.main.name,
            "--region",
            data.aws_region.current.name
          ]
        }
      }
    }]
  }
  sensitive = true
}

# Connection Information for kubectl
output "kubectl_config" {
  description = "kubectl configuration commands"
  value = {
    update_kubeconfig_command = "aws eks update-kubeconfig --region ${data.aws_region.current.name} --name ${aws_eks_cluster.main.name}"
    cluster_name              = aws_eks_cluster.main.name
    region                    = data.aws_region.current.name
  }
}