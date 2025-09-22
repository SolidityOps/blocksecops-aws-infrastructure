# ECR Module - Creates ECR repositories with vulnerability scanning

# ECR Repositories
resource "aws_ecr_repository" "repositories" {
  for_each = toset(var.repositories)

  name                 = "${var.project_name}/${each.value}"
  image_tag_mutability = var.image_tag_mutability

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  encryption_configuration {
    encryption_type = var.encryption_type
    kms_key         = var.kms_key_arn
  }

  tags = merge(
    {
      Name        = "${var.project_name}-${each.value}"
      Repository  = each.value
      Environment = var.environment
    },
    var.tags
  )
}

# ECR Lifecycle Policies
resource "aws_ecr_lifecycle_policy" "repositories" {
  for_each = toset(var.repositories)

  repository = aws_ecr_repository.repositories[each.value].name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last ${var.max_image_count} images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v"]
          countType     = "imageCountMoreThan"
          countNumber   = var.max_image_count
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Delete untagged images older than ${var.untagged_image_retention_days} days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = var.untagged_image_retention_days
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 3
        description  = "Keep production images indefinitely"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["prod", "production"]
          countType     = "imageCountMoreThan"
          countNumber   = 999
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# ECR Repository Policies for cross-account access (if needed)
resource "aws_ecr_repository_policy" "repositories" {
  for_each = var.enable_cross_region_replication ? toset(var.repositories) : []

  repository = aws_ecr_repository.repositories[each.value].name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCrossRegionReplication"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:DescribeRepositories",
          "ecr:GetRepositoryPolicy",
          "ecr:ListImages",
          "ecr:DeleteRepository",
          "ecr:BatchDeleteImage",
          "ecr:SetRepositoryPolicy",
          "ecr:DeleteRepositoryPolicy"
        ]
      }
    ]
  })
}

# ECR Replication Configuration (for cross-region replication)
resource "aws_ecr_replication_configuration" "main" {
  count = var.enable_cross_region_replication ? 1 : 0

  replication_configuration {
    rule {
      destination {
        region      = var.replication_destination_region
        registry_id = data.aws_caller_identity.current.account_id
      }

      repository_filter {
        filter      = "${var.project_name}/*"
        filter_type = "PREFIX_MATCH"
      }
    }
  }
}

# Registry Scanning Configuration
resource "aws_ecr_registry_scanning_configuration" "main" {
  count = var.enable_registry_scanning ? 1 : 0

  scan_type = var.registry_scan_type

  dynamic "rule" {
    for_each = var.registry_scan_rules
    content {
      scan_frequency = rule.value.scan_frequency
      repository_filter {
        filter      = rule.value.filter
        filter_type = rule.value.filter_type
      }
    }
  }
}

# Data source for current AWS account
data "aws_caller_identity" "current" {}

# Registry Policy for organization-wide settings
resource "aws_ecr_registry_policy" "main" {
  count = var.enable_registry_policy ? 1 : 0

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowRepositoryAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = "*"
      }
    ]
  })
}

# ECR Pull Through Cache Rules (for public registries)
resource "aws_ecr_pull_through_cache_rule" "rules" {
  for_each = var.pull_through_cache_rules

  ecr_repository_prefix = each.key
  upstream_registry_url = each.value.upstream_registry_url
}

# CloudWatch Log Group for ECR events
resource "aws_cloudwatch_log_group" "ecr" {
  count = var.enable_cloudwatch_logging ? 1 : 0

  name              = "/aws/ecr/${var.project_name}"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn

  tags = {
    Name = "${var.project_name}-ecr-logs"
  }
}

# EventBridge rule for ECR scan results
resource "aws_cloudwatch_event_rule" "ecr_scan_results" {
  count = var.enable_scan_result_notifications ? 1 : 0

  name        = "${var.project_name}-${var.environment}-ecr-scan-results"
  description = "Capture ECR image scan results"

  event_pattern = jsonencode({
    source      = ["aws.ecr"]
    detail-type = ["ECR Image Scan"]
    detail = {
      result = ["COMPLETE"]
      repository-name = [for repo in var.repositories : "${var.project_name}/${repo}"]
    }
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-ecr-scan-results"
  }
}

# SNS topic for ECR notifications (optional)
resource "aws_sns_topic" "ecr_notifications" {
  count = var.enable_scan_result_notifications ? 1 : 0

  name              = "${var.project_name}-${var.environment}-ecr-notifications"
  kms_master_key_id = var.kms_key_arn

  tags = {
    Name = "${var.project_name}-${var.environment}-ecr-notifications"
  }
}

# EventBridge target for SNS
resource "aws_cloudwatch_event_target" "ecr_scan_sns" {
  count = var.enable_scan_result_notifications ? 1 : 0

  rule      = aws_cloudwatch_event_rule.ecr_scan_results[0].name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.ecr_notifications[0].arn

  input_transformer {
    input_paths = {
      repository = "$.detail.repository-name"
      tag        = "$.detail.image-tags[0]"
      findings   = "$.detail.finding-counts"
    }
    input_template = jsonencode({
      repository = "<repository>"
      tag        = "<tag>"
      findings   = "<findings>"
      message    = "ECR scan completed for <repository>:<tag>"
    })
  }
}