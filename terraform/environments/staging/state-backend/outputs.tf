# Outputs for Staging State Backend Configuration

# Pass through module outputs
output "s3_bucket_id" {
  description = "The ID of the S3 bucket used for Terraform state storage"
  value       = module.state_backend.s3_bucket_id
}

output "s3_bucket_arn" {
  description = "The ARN of the S3 bucket used for Terraform state storage"
  value       = module.state_backend.s3_bucket_arn
}

output "s3_bucket_region" {
  description = "The AWS region where the S3 bucket resides"
  value       = module.state_backend.s3_bucket_region
}

output "dynamodb_table_id" {
  description = "The ID of the DynamoDB table used for Terraform state locking"
  value       = module.state_backend.dynamodb_table_id
}

output "dynamodb_table_name" {
  description = "The name of the DynamoDB table used for Terraform state locking"
  value       = module.state_backend.dynamodb_table_name
}

# Backend configuration for easy reference
output "backend_config" {
  description = "Backend configuration for staging environment"
  value       = module.state_backend.backend_config_staging
}

# Instructions output
output "setup_instructions" {
  description = "Instructions for setting up backend configuration"
  value = <<-EOT
    Backend infrastructure deployed successfully!

    To use this backend for staging networking:
    1. Copy the backend-template.tfvars file to backend.tfvars
    2. Replace placeholders with these values:
       - bucket: ${module.state_backend.s3_bucket_id}
       - dynamodb_table: ${module.state_backend.dynamodb_table_name}
    3. Initialize Terraform with: terraform init -backend-config=backend.tfvars

    Backend Configuration:
    - S3 Bucket: ${module.state_backend.s3_bucket_id}
    - DynamoDB Table: ${module.state_backend.dynamodb_table_name}
    - Region: ${module.state_backend.s3_bucket_region}
    - State Key: networking/staging/terraform.tfstate
  EOT
}

# Summary for staging environment
output "summary" {
  description = "Summary of the staging state backend deployment"
  value       = module.state_backend.summary
}