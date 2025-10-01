# Production EKS Environment Variables

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
  default     = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
}

# EKS Cluster Configuration - Production Optimized
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
  description = "Enable public API server endpoint - restricted for production"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "CIDR blocks that can access the public API server endpoint - restricted for production"
  type        = list(string)
  default     = ["0.0.0.0/0"] # Should be restricted to specific IP ranges in production
}

variable "cluster_service_ipv4_cidr" {
  description = "CIDR block for Kubernetes service IP addresses"
  type        = string
  default     = "172.20.0.0/16"
}

variable "cluster_enabled_log_types" {
  description = "List of control plane logging to enable - comprehensive for production"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "cluster_authentication_mode" {
  description = "Authentication mode for the cluster"
  type        = string
  default     = "API_AND_CONFIG_MAP"
}

# Node Groups Configuration - Production Optimized
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
  }))
  default = {
    default = {
      instance_types    = ["m5.large"]
      desired_size      = 3
      min_size          = 3
      max_size          = 10
      disk_size         = 50
      capacity_type     = "ON_DEMAND"
      enable_monitoring = true
      k8s_labels = {
        role        = "worker"
        environment = "production"
        cost_center = "production"
      }
    }
    spot = {
      instance_types    = ["m5.large", "m5.xlarge", "m4.large"]
      desired_size      = 2
      min_size          = 0
      max_size          = 5
      disk_size         = 50
      capacity_type     = "SPOT"
      enable_monitoring = true
      k8s_labels = {
        role        = "worker"
        environment = "production"
        cost_center = "production"
        capacity    = "spot"
      }
      k8s_taints = [
        {
          key    = "spot-instance"
          value  = "true"
          effect = "NO_SCHEDULE"
        }
      ]
    }
  }
}

# Security Configuration - Enhanced for Production
variable "enable_encryption" {
  description = "Enable encryption for EKS cluster secrets"
  type        = bool
  default     = true
}

variable "create_cluster_security_group" {
  description = "Create additional security group for EKS cluster"
  type        = bool
  default     = true
}

variable "enable_cluster_admin_access" {
  description = "Enable cluster admin access for root account"
  type        = bool
  default     = true
}

# Add-ons Configuration - Comprehensive for Production
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
  default     = true
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

# Monitoring Configuration - Comprehensive for Production
variable "log_retention_days" {
  description = "CloudWatch log retention period - extended for production compliance"
  type        = number
  default     = 30
}