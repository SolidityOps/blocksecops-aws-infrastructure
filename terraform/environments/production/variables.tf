# Variables for Production Environment

variable "aws_region" {
  description = "AWS region for production environment"
  type        = string
  default     = "us-west-2"
}

variable "vpc_cidr" {
  description = "CIDR block for production VPC"
  type        = string
  default     = "10.1.0.0/16"  # Different CIDR range from staging
}

variable "public_subnet_cidr" {
  description = "CIDR block for production public subnet"
  type        = string
  default     = "10.1.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block for production private subnet"
  type        = string
  default     = "10.1.2.0/24"
}

variable "log_retention_days" {
  description = "VPC Flow Logs retention period for production"
  type        = number
  default     = 90  # Longer retention for production compliance
}

variable "common_tags" {
  description = "Common tags for production resources"
  type        = map(string)
  default = {
    Environment = "production"
    Project     = "SoliditySecurityPlatform"
    ManagedBy   = "Terraform"
    Owner       = "DevOps"
    CostCenter  = "Production"
    Backup      = "Required"
  }
}