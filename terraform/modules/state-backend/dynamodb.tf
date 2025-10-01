# DynamoDB Table for Terraform State Locking
# Configured with point-in-time recovery and encryption

# DynamoDB table for Terraform state locking
resource "aws_dynamodb_table" "terraform_state_lock" {
  name           = "${var.project}-${var.environment}-terraform-state-lock"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  server_side_encryption {
    enabled = true
  }

  point_in_time_recovery {
    enabled = var.enable_point_in_time_recovery
  }

  tags = merge(var.common_tags, {
    Name        = "${var.project}-${var.environment}-terraform-state-lock"
    Purpose     = "terraform-state-locking"
    Environment = var.environment
    Component   = "state-backend"
  })

  lifecycle {
    prevent_destroy = true
  }
}

# DynamoDB table item TTL configuration (optional)
resource "aws_dynamodb_table" "terraform_state_lock_ttl" {
  count = var.enable_lock_ttl ? 1 : 0

  name           = "${var.project}-${var.environment}-terraform-state-lock-ttl"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  ttl {
    attribute_name = "TTL"
    enabled        = true
  }

  server_side_encryption {
    enabled = true
  }

  point_in_time_recovery {
    enabled = var.enable_point_in_time_recovery
  }

  tags = merge(var.common_tags, {
    Name        = "${var.project}-${var.environment}-terraform-state-lock-ttl"
    Purpose     = "terraform-state-locking-with-ttl"
    Environment = var.environment
    Component   = "state-backend"
  })

  lifecycle {
    prevent_destroy = true
  }
}

# CloudWatch alarm for DynamoDB table errors
resource "aws_cloudwatch_metric_alarm" "dynamodb_errors" {
  count = var.enable_monitoring ? 1 : 0

  alarm_name          = "${var.project}-${var.environment}-dynamodb-state-lock-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "UserErrors"
  namespace           = "AWS/DynamoDB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "This metric monitors DynamoDB errors for Terraform state locking"
  alarm_actions       = var.sns_topic_arn != "" ? [var.sns_topic_arn] : []

  dimensions = {
    TableName = aws_dynamodb_table.terraform_state_lock.name
  }

  tags = merge(var.common_tags, {
    Name        = "${var.project}-${var.environment}-dynamodb-state-lock-errors"
    Environment = var.environment
    Component   = "state-backend-monitoring"
  })
}

# CloudWatch alarm for DynamoDB throttling
resource "aws_cloudwatch_metric_alarm" "dynamodb_throttling" {
  count = var.enable_monitoring ? 1 : 0

  alarm_name          = "${var.project}-${var.environment}-dynamodb-state-lock-throttling"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ThrottledRequests"
  namespace           = "AWS/DynamoDB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "This metric monitors DynamoDB throttling for Terraform state locking"
  alarm_actions       = var.sns_topic_arn != "" ? [var.sns_topic_arn] : []

  dimensions = {
    TableName = aws_dynamodb_table.terraform_state_lock.name
  }

  tags = merge(var.common_tags, {
    Name        = "${var.project}-${var.environment}-dynamodb-state-lock-throttling"
    Environment = var.environment
    Component   = "state-backend-monitoring"
  })
}