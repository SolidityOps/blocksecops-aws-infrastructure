# Variables for Staging Environment

variable "aws_region" {
  description = "AWS region for staging environment"
  type        = string
  default     = "us-west-2"
}

variable "vpc_cidr" {
  description = "CIDR block for staging VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for staging public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block for staging private subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "log_retention_days" {
  description = "VPC Flow Logs retention period for staging"
  type        = number
  default     = 7  # Shorter retention for staging to reduce costs
}

variable "common_tags" {
  description = "Common tags for staging resources"
  type        = map(string)
  default = {
    Environment = "staging"
    Project     = "SoliditySecurityPlatform"
    ManagedBy   = "Terraform"
    Owner       = "DevOps"
    CostCenter  = "Development"
  }
}