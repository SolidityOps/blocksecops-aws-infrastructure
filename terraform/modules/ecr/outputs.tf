# ECR Module Outputs

output "repository_urls" {
  description = "Map of repository names to URLs"
  value = {
    for name, repo in aws_ecr_repository.repositories : name => repo.repository_url
  }
}

output "repository_arns" {
  description = "Map of repository names to ARNs"
  value = {
    for name, repo in aws_ecr_repository.repositories : name => repo.arn
  }
}

output "repository_registry_ids" {
  description = "Map of repository names to registry IDs"
  value = {
    for name, repo in aws_ecr_repository.repositories : name => repo.registry_id
  }
}

output "repository_names" {
  description = "List of repository names"
  value       = [for repo in aws_ecr_repository.repositories : repo.name]
}

# Individual repository outputs for easier reference
output "api_service_repository_url" {
  description = "URL of API service repository"
  value       = contains(var.repositories, "api-service") ? aws_ecr_repository.repositories["api-service"].repository_url : null
}

output "tool_integration_repository_url" {
  description = "URL of tool integration service repository"
  value       = contains(var.repositories, "tool-integration-service") ? aws_ecr_repository.repositories["tool-integration-service"].repository_url : null
}

output "orchestration_repository_url" {
  description = "URL of orchestration service repository"
  value       = contains(var.repositories, "orchestration-service") ? aws_ecr_repository.repositories["orchestration-service"].repository_url : null
}

output "intelligence_engine_repository_url" {
  description = "URL of intelligence engine service repository"
  value       = contains(var.repositories, "intelligence-engine-service") ? aws_ecr_repository.repositories["intelligence-engine-service"].repository_url : null
}

output "data_service_repository_url" {
  description = "URL of data service repository"
  value       = contains(var.repositories, "data-service") ? aws_ecr_repository.repositories["data-service"].repository_url : null
}

output "notification_service_repository_url" {
  description = "URL of notification service repository"
  value       = contains(var.repositories, "notification-service") ? aws_ecr_repository.repositories["notification-service"].repository_url : null
}

output "frontend_repository_url" {
  description = "URL of frontend repository"
  value       = contains(var.repositories, "frontend") ? aws_ecr_repository.repositories["frontend"].repository_url : null
}

# SNS topic for notifications
output "ecr_notifications_topic_arn" {
  description = "ARN of SNS topic for ECR notifications"
  value       = var.enable_scan_result_notifications ? aws_sns_topic.ecr_notifications[0].arn : null
}

# CloudWatch log group
output "cloudwatch_log_group_name" {
  description = "Name of CloudWatch log group for ECR"
  value       = var.enable_cloudwatch_logging ? aws_cloudwatch_log_group.ecr[0].name : null
}

# Registry configuration
output "registry_id" {
  description = "The registry ID where the repositories reside"
  value       = data.aws_caller_identity.current.account_id
}

# Login commands for different services
output "docker_login_command" {
  description = "Docker login command for ECR"
  value       = "aws ecr get-login-password --region ${data.aws_region.current.name} | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com"
}

# Data source for current region
data "aws_region" "current" {}

# Repository information summary
output "repository_summary" {
  description = "Summary of all ECR repositories"
  value = {
    total_repositories = length(var.repositories)
    scan_on_push      = var.scan_on_push
    encryption_type   = var.encryption_type
    repositories      = {
      for name, repo in aws_ecr_repository.repositories : name => {
        url         = repo.repository_url
        arn         = repo.arn
        registry_id = repo.registry_id
      }
    }
  }
}