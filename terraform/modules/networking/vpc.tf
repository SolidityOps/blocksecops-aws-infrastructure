# VPC Configuration for Solidity Security Platform
# Single-AZ deployment for MVP cost optimization

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.common_tags, {
    Name        = "${var.environment}-solidity-security-vpc"
    Environment = var.environment
    Purpose     = "Main VPC for Solidity Security Platform"
  })
}

# Internet Gateway for public subnet internet access
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.common_tags, {
    Name        = "${var.environment}-solidity-security-igw"
    Environment = var.environment
  })
}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"

  depends_on = [aws_internet_gateway.main]

  tags = merge(var.common_tags, {
    Name        = "${var.environment}-solidity-security-nat-eip"
    Environment = var.environment
  })
}