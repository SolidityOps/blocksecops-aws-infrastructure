# VPC Flow Logs Configuration for Network Monitoring and Security Analysis
# Using S3 storage instead of CloudWatch for cost optimization

# S3 bucket for VPC Flow Logs
resource "aws_s3_bucket" "vpc_flow_logs" {
  bucket = "${var.environment}-solidity-security-vpc-flow-logs-${random_id.bucket_suffix.hex}"

  tags = merge(var.common_tags, {
    Name        = "${var.environment}-solidity-security-vpc-flow-logs"
    Environment = var.environment
    Service     = "VPC-FlowLogs"
  })
}

# Random ID for unique S3 bucket naming
resource "random_id" "bucket_suffix" {
  byte_length = 8
}

# S3 bucket versioning
resource "aws_s3_bucket_versioning" "vpc_flow_logs" {
  bucket = aws_s3_bucket.vpc_flow_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 bucket encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "vpc_flow_logs" {
  bucket = aws_s3_bucket.vpc_flow_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 bucket lifecycle configuration
resource "aws_s3_bucket_lifecycle_configuration" "vpc_flow_logs" {
  bucket = aws_s3_bucket.vpc_flow_logs.id

  rule {
    id     = "vpc_flow_logs_lifecycle"
    status = "Enabled"

    expiration {
      days = var.log_retention_days
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

# S3 bucket public access block
resource "aws_s3_bucket_public_access_block" "vpc_flow_logs" {
  bucket = aws_s3_bucket.vpc_flow_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# VPC Flow Logs to S3
resource "aws_flow_log" "vpc" {
  log_destination      = aws_s3_bucket.vpc_flow_logs.arn
  log_destination_type = "s3"
  traffic_type         = "ALL"
  vpc_id               = var.vpc_id

  tags = merge(var.common_tags, {
    Name        = "${var.environment}-solidity-security-vpc-flow-logs"
    Environment = var.environment
    Service     = "VPC-FlowLogs"
  })
}