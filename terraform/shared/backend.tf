# S3 + DynamoDB backend configuration for Terraform state
terraform {
  backend "s3" {
    bucket         = "solidity-security-terraform-state-${var.environment}"
    key            = "infrastructure/terraform.tfstate"
    region         = var.aws_region
    dynamodb_table = "solidity-security-terraform-locks-${var.environment}"
    encrypt        = true

    # Versioning for state file history
    versioning = true

    # Server-side encryption
    server_side_encryption_configuration {
      rule {
        apply_server_side_encryption_by_default {
          sse_algorithm = "AES256"
        }
      }
    }
  }
}

# S3 bucket for Terraform state
resource "aws_s3_bucket" "terraform_state" {
  bucket = "solidity-security-terraform-state-${var.environment}"

  tags = {
    Name        = "solidity-security-terraform-state-${var.environment}"
    Environment = var.environment
    Purpose     = "terraform-state"
    Project     = "solidity-security"
  }
}

# S3 bucket versioning
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 bucket encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 bucket public access block
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# DynamoDB table for Terraform locks
resource "aws_dynamodb_table" "terraform_locks" {
  name           = "solidity-security-terraform-locks-${var.environment}"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "solidity-security-terraform-locks-${var.environment}"
    Environment = var.environment
    Purpose     = "terraform-locks"
    Project     = "solidity-security"
  }
}