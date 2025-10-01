# EKS Module Variables

# General variables
variable "project" {
  description = "Project name"
  type        = string
  default     = "solidity-security"
}

variable "environment" {
  description = "Environment name (staging, production)"
  type        = string
  validation {
    condition     = contains(["staging", "production"], var.environment)
    error_message = "Environment must be either staging or production."
  }
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}

# Network Configuration
variable "vpc_id" {
  description = "VPC ID where EKS cluster will be created"
  type        = string
}

variable "cluster_subnet_ids" {
  description = "Subnet IDs for EKS cluster (should include both private and public for mixed deployments)"
  type        = list(string)
}

variable "node_group_subnet_ids" {
  description = "Subnet IDs for EKS node groups (typically private subnets)"
  type        = list(string)
}

variable "cluster_security_group_ids" {
  description = "Security group IDs for EKS cluster"
  type        = list(string)
  default     = []
}

variable "node_security_group_ids" {
  description = "Security group IDs for EKS node groups"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks of private subnets (for security group rules)"
  type        = list(string)
  default     = []
}

# EKS Cluster Configuration
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
  description = "Enable public API server endpoint"
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
  description = "List of control plane logging to enable"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "cluster_authentication_mode" {
  description = "Authentication mode for the cluster (API, API_AND_CONFIG_MAP, CONFIG_MAP)"
  type        = string
  default     = "API_AND_CONFIG_MAP"
  validation {
    condition     = contains(["API", "API_AND_CONFIG_MAP", "CONFIG_MAP"], var.cluster_authentication_mode)
    error_message = "Authentication mode must be API, API_AND_CONFIG_MAP, or CONFIG_MAP."
  }
}

variable "bootstrap_cluster_creator_admin_permissions" {
  description = "Bootstrap cluster creator admin permissions"
  type        = bool
  default     = true
}

# Node Groups Configuration
variable "node_groups" {
  description = "Map of EKS node group configurations"
  type = map(object({
    instance_types = list(string)
    desired_size   = number
    min_size       = number
    max_size       = number
    disk_size      = optional(number, 50)
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
    enable_monitoring          = optional(bool, true)
    bootstrap_extra_args       = optional(string, "")
    block_device_mappings = optional(list(object({
      device_name = string
      volume_size = optional(number, 50)
      volume_type = optional(string, "gp3")
      encrypted   = optional(bool, true)
    })), [])
  }))
  default = {
    default = {
      instance_types = ["t3.medium"]
      desired_size   = 2
      min_size       = 1
      max_size       = 4
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

# Add-ons Configuration
variable "enable_coredns_addon" {
  description = "Enable CoreDNS EKS add-on"
  type        = bool
  default     = true
}

variable "coredns_version" {
  description = "CoreDNS add-on version"
  type        = string
  default     = null
}

variable "coredns_configuration" {
  description = "CoreDNS add-on configuration"
  type        = string
  default     = null
}

variable "enable_kube_proxy_addon" {
  description = "Enable kube-proxy EKS add-on"
  type        = bool
  default     = true
}

variable "kube_proxy_version" {
  description = "kube-proxy add-on version"
  type        = string
  default     = null
}

variable "kube_proxy_configuration" {
  description = "kube-proxy add-on configuration"
  type        = string
  default     = null
}

variable "enable_vpc_cni_addon" {
  description = "Enable VPC CNI EKS add-on"
  type        = bool
  default     = true
}

variable "vpc_cni_version" {
  description = "VPC CNI add-on version"
  type        = string
  default     = null
}

variable "vpc_cni_configuration" {
  description = "VPC CNI add-on configuration"
  type        = string
  default     = null
}

variable "enable_ebs_csi_addon" {
  description = "Enable EBS CSI driver EKS add-on"
  type        = bool
  default     = true
}

variable "ebs_csi_version" {
  description = "EBS CSI driver add-on version"
  type        = string
  default     = null
}

variable "ebs_csi_configuration" {
  description = "EBS CSI driver add-on configuration"
  type        = string
  default     = null
}

variable "enable_pod_identity_addon" {
  description = "Enable EKS Pod Identity Agent add-on"
  type        = bool
  default     = false
}

variable "pod_identity_version" {
  description = "EKS Pod Identity Agent add-on version"
  type        = string
  default     = null
}

variable "pod_identity_configuration" {
  description = "EKS Pod Identity Agent add-on configuration"
  type        = string
  default     = null
}

# Service Account Roles Configuration
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

# Monitoring Configuration
variable "log_retention_days" {
  description = "CloudWatch log retention period (days)"
  type        = number
  default     = 14
}