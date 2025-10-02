# S3 Bucket for Terraform State Storage
# Configured with versioning, encryption, and security best practices

# Generate a random suffix for bucket name uniqueness
resource "random_id" "bucket_suffix" {
  byte_length = 8
}

# S3 bucket for Terraform state storage
resource "aws_s3_bucket" "terraform_state" {
  bucket = "${var.project}-${var.environment}-terraform-state-${random_id.bucket_suffix.hex}"

  tags = merge(var.common_tags, {
    Name        = "${var.project}-${var.environment}-terraform-state"
    Purpose     = "terraform-state-storage"
    Environment = var.environment
    Component   = "state-backend"
  })

  # lifecycle {
  #   prevent_destroy = true
  # }
}

# S3 bucket versioning configuration
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# S3 bucket server-side encryption configuration
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
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

# S3 bucket lifecycle configuration
resource "aws_s3_bucket_lifecycle_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    id     = "terraform_state_lifecycle"
    status = "Enabled"

    filter {
      prefix = ""
    }

    # Keep current versions
    expiration {
      days = 0
    }

    # Clean up old versions
    noncurrent_version_expiration {
      noncurrent_days = var.state_retention_days
    }

    # Clean up incomplete multipart uploads
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# S3 bucket policy for secure access
resource "aws_s3_bucket_policy" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyInsecureConnections"
        Effect = "Deny"
        Principal = "*"
        Action = "s3:*"
        Resource = [
          aws_s3_bucket.terraform_state.arn,
          "${aws_s3_bucket.terraform_state.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      },
      {
        Sid    = "DenyUnencryptedObjectUploads"
        Effect = "Deny"
        Principal = "*"
        Action = "s3:PutObject"
        Resource = "${aws_s3_bucket.terraform_state.arn}/*"
        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption" = "AES256"
          }
        }
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.terraform_state]
}

# S3 bucket logging (optional)
resource "aws_s3_bucket_logging" "terraform_state" {
  count = var.enable_access_logging ? 1 : 0

  bucket = aws_s3_bucket.terraform_state.id

  target_bucket = var.access_log_bucket
  target_prefix = "terraform-state-access-logs/"
}

# S3 bucket notification for state changes (optional)
resource "aws_s3_bucket_notification" "terraform_state" {
  count  = var.enable_notifications ? 1 : 0
  bucket = aws_s3_bucket.terraform_state.id

  eventbridge = true
}