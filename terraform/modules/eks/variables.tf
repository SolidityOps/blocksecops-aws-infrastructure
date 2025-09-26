# EKS Module Variables
# Variables for configuring EKS clusters and node groups

# Cluster Configuration
variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.28"
}

variable "vpc_id" {
  description = "VPC ID where the cluster will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the EKS cluster"
  type        = list(string)
}

variable "endpoint_private_access" {
  description = "Enable private API server endpoint"
  type        = bool
  default     = true
}

variable "endpoint_public_access" {
  description = "Enable public API server endpoint"
  type        = bool
  default     = true
}

variable "public_access_cidrs" {
  description = "List of CIDR blocks for public access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "enabled_cluster_log_types" {
  description = "List of control plane logging types to enable"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "cloudwatch_log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 7
}

variable "kms_key_arn" {
  description = "ARN of the KMS key for envelope encryption"
  type        = string
  default     = ""
}

# Node Group Configuration
variable "node_group_name" {
  description = "Name of the EKS node group"
  type        = string
  default     = "main"
}

variable "node_group_subnet_ids" {
  description = "List of subnet IDs for the node group"
  type        = list(string)
}

variable "node_group_instance_types" {
  description = "List of instance types for the node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_group_capacity_type" {
  description = "Capacity type for the node group (ON_DEMAND or SPOT)"
  type        = string
  default     = "ON_DEMAND"
}

variable "node_group_disk_size" {
  description = "Disk size in GB for worker nodes"
  type        = number
  default     = 20
}

variable "node_group_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "node_group_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 4
}

variable "node_group_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "node_group_max_unavailable_percentage" {
  description = "Maximum percentage of nodes unavailable during update"
  type        = number
  default     = 25
}

variable "node_group_ami_type" {
  description = "AMI type for the node group"
  type        = string
  default     = "AL2_x86_64"
}

variable "node_group_release_version" {
  description = "AMI release version for the node group"
  type        = string
  default     = ""
}

variable "node_group_ssh_key" {
  description = "EC2 Key Pair name for SSH access to nodes"
  type        = string
  default     = ""
}

variable "node_group_ssh_security_groups" {
  description = "Security groups for SSH access to nodes"
  type        = list(string)
  default     = []
}

variable "node_group_labels" {
  description = "Kubernetes labels for the node group"
  type        = map(string)
  default     = {}
}

variable "node_group_taint_key" {
  description = "Key for node group taint"
  type        = string
  default     = ""
}

variable "node_group_taint_value" {
  description = "Value for node group taint"
  type        = string
  default     = ""
}

variable "node_group_taint_effect" {
  description = "Effect for node group taint"
  type        = string
  default     = "NO_SCHEDULE"
}

# Launch Template Configuration
variable "use_launch_template" {
  description = "Whether to use launch template for advanced configuration"
  type        = bool
  default     = false
}

# Secondary Node Group Configuration
variable "create_secondary_node_group" {
  description = "Whether to create a secondary node group"
  type        = bool
  default     = false
}

variable "secondary_node_group_subnet_ids" {
  description = "List of subnet IDs for the secondary node group"
  type        = list(string)
  default     = []
}

variable "secondary_node_group_instance_types" {
  description = "List of instance types for the secondary node group"
  type        = list(string)
  default     = ["t3.small"]
}

variable "secondary_node_group_capacity_type" {
  description = "Capacity type for the secondary node group"
  type        = string
  default     = "SPOT"
}

variable "secondary_node_group_disk_size" {
  description = "Disk size in GB for secondary worker nodes"
  type        = number
  default     = 20
}

variable "secondary_node_group_desired_size" {
  description = "Desired number of secondary worker nodes"
  type        = number
  default     = 1
}

variable "secondary_node_group_max_size" {
  description = "Maximum number of secondary worker nodes"
  type        = number
  default     = 3
}

variable "secondary_node_group_min_size" {
  description = "Minimum number of secondary worker nodes"
  type        = number
  default     = 0
}

variable "secondary_node_group_max_unavailable_percentage" {
  description = "Maximum percentage of secondary nodes unavailable during update"
  type        = number
  default     = 25
}

variable "secondary_node_group_ami_type" {
  description = "AMI type for the secondary node group"
  type        = string
  default     = "AL2_x86_64"
}

variable "secondary_node_group_labels" {
  description = "Kubernetes labels for the secondary node group"
  type        = map(string)
  default = {
    "node-type" = "spot"
  }
}

# CloudWatch Monitoring Configuration
variable "enable_container_insights" {
  description = "Enable CloudWatch Container Insights for the cluster"
  type        = bool
  default     = true
}

variable "sns_topic_arn" {
  description = "SNS topic ARN for CloudWatch alarms"
  type        = string
  default     = ""
}

# Common tags
variable "tags" {
  description = "A map of tags to assign to the resources"
  type        = map(string)
  default     = {}
}