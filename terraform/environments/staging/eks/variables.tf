# Staging EKS Environment Variables

# General variables
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "project" {
  description = "Project name"
  type        = string
  default     = "solidity-security"
}

variable "terraform_state_bucket" {
  description = "S3 bucket for Terraform state"
  type        = string
  default     = "solidity-security-terraform-state"
}

variable "additional_tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}

# Network Configuration
variable "private_subnet_cidrs" {
  description = "CIDR blocks of private subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

# EKS Cluster Configuration - Staging Optimized
variable "cluster_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
  default     = "1.28"
}

variable "cluster_endpoint_private_access" {
  description = "Enable private API server endpoint"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access" {
  description = "Enable public API server endpoint - enabled for staging access"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "CIDR blocks that can access the public API server endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "cluster_service_ipv4_cidr" {
  description = "CIDR block for Kubernetes service IP addresses"
  type        = string
  default     = "172.20.0.0/16"
}

variable "cluster_enabled_log_types" {
  description = "List of control plane logging to enable - minimal for staging"
  type        = list(string)
  default     = ["api", "audit"]
}

variable "cluster_authentication_mode" {
  description = "Authentication mode for the cluster"
  type        = string
  default     = "API_AND_CONFIG_MAP"
}

# Node Groups Configuration - Cost Optimized
variable "node_groups" {
  description = "Map of EKS node group configurations"
  type = map(object({
    instance_types = list(string)
    desired_size   = number
    min_size       = number
    max_size       = number
    disk_size      = optional(number, 30)
    ami_type       = optional(string, "AL2_x86_64")
    capacity_type  = optional(string, "ON_DEMAND")
    k8s_labels     = optional(map(string), {})
    k8s_taints = optional(list(object({
      key    = string
      value  = string
      effect = string
    })), [])
    max_unavailable_percentage = optional(number, 25)
    enable_cluster_autoscaler  = optional(bool, true)
    enable_monitoring          = optional(bool, false)
    bootstrap_extra_args       = optional(string, "")
  }))
  default = {
    default = {
      # Phase 1 Cost Optimization: t3.small instead of t3.medium
      instance_types    = ["t3.small"]
      desired_size      = 1
      min_size          = 1
      max_size          = 2  # Reduced from 3 for cost optimization
      disk_size         = 30
      capacity_type     = "ON_DEMAND"
      enable_monitoring = false
      k8s_labels = {
        role        = "worker"
        environment = "staging"
        cost_center = "engineering"
      }
    }
  }
}

# Security Configuration
variable "enable_encryption" {
  description = "Enable encryption for EKS cluster secrets"
  type        = bool
  default     = true
}

variable "create_cluster_security_group" {
  description = "Create additional security group for EKS cluster"
  type        = bool
  default     = false
}

variable "enable_cluster_admin_access" {
  description = "Enable cluster admin access for root account"
  type        = bool
  default     = true
}

# Add-ons Configuration - Basic for Staging
variable "enable_coredns_addon" {
  description = "Enable CoreDNS EKS add-on"
  type        = bool
  default     = true
}

variable "enable_kube_proxy_addon" {
  description = "Enable kube-proxy EKS add-on"
  type        = bool
  default     = true
}

variable "enable_vpc_cni_addon" {
  description = "Enable VPC CNI EKS add-on"
  type        = bool
  default     = true
}

variable "enable_ebs_csi_addon" {
  description = "Enable EBS CSI driver EKS add-on"
  type        = bool
  default     = true
}

variable "enable_pod_identity_addon" {
  description = "Enable EKS Pod Identity Agent add-on"
  type        = bool
  default     = false
}

# Service Account Roles
variable "enable_aws_load_balancer_controller" {
  description = "Create IAM role for AWS Load Balancer Controller"
  type        = bool
  default     = true
}

variable "enable_cluster_autoscaler" {
  description = "Create IAM role for Cluster Autoscaler"
  type        = bool
  default     = true
}

# Monitoring Configuration - Basic for Staging
variable "log_retention_days" {
  description = "CloudWatch log retention period - shorter for staging cost optimization"
  type        = number
  default     = 7
}