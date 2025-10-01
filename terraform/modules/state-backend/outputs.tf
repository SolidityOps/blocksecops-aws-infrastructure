# Outputs for Terraform State Backend Module

# S3 Bucket Outputs
output "s3_bucket_id" {
  description = "The ID of the S3 bucket used for Terraform state storage"
  value       = aws_s3_bucket.terraform_state.id
}

output "s3_bucket_arn" {
  description = "The ARN of the S3 bucket used for Terraform state storage"
  value       = aws_s3_bucket.terraform_state.arn
}

output "s3_bucket_domain_name" {
  description = "The domain name of the S3 bucket"
  value       = aws_s3_bucket.terraform_state.bucket_domain_name
}

output "s3_bucket_regional_domain_name" {
  description = "The regional domain name of the S3 bucket"
  value       = aws_s3_bucket.terraform_state.bucket_regional_domain_name
}

output "s3_bucket_region" {
  description = "The AWS region where the S3 bucket resides"
  value       = aws_s3_bucket.terraform_state.region
}

# DynamoDB Table Outputs
output "dynamodb_table_id" {
  description = "The ID of the DynamoDB table used for Terraform state locking"
  value       = aws_dynamodb_table.terraform_state_lock.id
}

output "dynamodb_table_arn" {
  description = "The ARN of the DynamoDB table used for Terraform state locking"
  value       = aws_dynamodb_table.terraform_state_lock.arn
}

output "dynamodb_table_name" {
  description = "The name of the DynamoDB table used for Terraform state locking"
  value       = aws_dynamodb_table.terraform_state_lock.name
}

# Backend Configuration Outputs
output "backend_config" {
  description = "Backend configuration block for use in other Terraform configurations"
  value = {
    bucket         = aws_s3_bucket.terraform_state.id
    region         = aws_s3_bucket.terraform_state.region
    dynamodb_table = aws_dynamodb_table.terraform_state_lock.name
    encrypt        = true
  }
}

output "backend_config_staging" {
  description = "Backend configuration for staging environment"
  value = {
    bucket         = aws_s3_bucket.terraform_state.id
    key            = "networking/staging/terraform.tfstate"
    region         = aws_s3_bucket.terraform_state.region
    dynamodb_table = aws_dynamodb_table.terraform_state_lock.name
    encrypt        = true
  }
}

output "backend_config_production" {
  description = "Backend configuration for production environment"
  value = {
    bucket         = aws_s3_bucket.terraform_state.id
    key            = "networking/production/terraform.tfstate"
    region         = aws_s3_bucket.terraform_state.region
    dynamodb_table = aws_dynamodb_table.terraform_state_lock.name
    encrypt        = true
  }
}

# Terraform Backend Configuration Files Content
output "staging_backend_config_content" {
  description = "Content for staging backend.tfvars file"
  value = <<-EOT
    bucket         = "${aws_s3_bucket.terraform_state.id}"
    key            = "networking/staging/terraform.tfstate"
    region         = "${aws_s3_bucket.terraform_state.region}"
    dynamodb_table = "${aws_dynamodb_table.terraform_state_lock.name}"
    encrypt        = true
  EOT
}

output "production_backend_config_content" {
  description = "Content for production backend.tfvars file"
  value = <<-EOT
    bucket         = "${aws_s3_bucket.terraform_state.id}"
    key            = "networking/production/terraform.tfstate"
    region         = "${aws_s3_bucket.terraform_state.region}"
    dynamodb_table = "${aws_dynamodb_table.terraform_state_lock.name}"
    encrypt        = true
  EOT
}

# Random ID Output (for troubleshooting)
output "bucket_suffix" {
  description = "Random suffix used in bucket name for uniqueness"
  value       = random_id.bucket_suffix.hex
}

# Monitoring Outputs
output "cloudwatch_alarm_dynamodb_errors_arn" {
  description = "ARN of the CloudWatch alarm for DynamoDB errors"
  value       = var.enable_monitoring ? aws_cloudwatch_metric_alarm.dynamodb_errors[0].arn : null
}

output "cloudwatch_alarm_dynamodb_throttling_arn" {
  description = "ARN of the CloudWatch alarm for DynamoDB throttling"
  value       = var.enable_monitoring ? aws_cloudwatch_metric_alarm.dynamodb_throttling[0].arn : null
}

# TTL Table Output (if enabled)
output "dynamodb_table_ttl_id" {
  description = "The ID of the DynamoDB TTL table (if enabled)"
  value       = var.enable_lock_ttl ? aws_dynamodb_table.terraform_state_lock_ttl[0].id : null
}

output "dynamodb_table_ttl_name" {
  description = "The name of the DynamoDB TTL table (if enabled)"
  value       = var.enable_lock_ttl ? aws_dynamodb_table.terraform_state_lock_ttl[0].name : null
}

# Summary Output for Easy Reference
output "summary" {
  description = "Summary of the Terraform state backend configuration"
  value = {
    s3_bucket_name      = aws_s3_bucket.terraform_state.id
    s3_bucket_region    = aws_s3_bucket.terraform_state.region
    dynamodb_table_name = aws_dynamodb_table.terraform_state_lock.name
    environment         = var.environment
    project             = var.project
    versioning_enabled  = "true"
    encryption_enabled  = "true"
    point_in_time_recovery = var.enable_point_in_time_recovery
  }
}