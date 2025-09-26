variable "environment" {
  description = "Environment name (staging/production)"
  type        = string
}

variable "redis_cluster_id" {
  description = "ElastiCache Redis cluster ID"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# CloudWatch Alarms for ElastiCache Redis
resource "aws_cloudwatch_metric_alarm" "redis_cpu_utilization" {
  alarm_name          = "${var.environment}-redis-cpu-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ElastiCache"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors redis cpu utilization"
  insufficient_data_actions = []

  dimensions = {
    CacheClusterId = var.redis_cluster_id
  }

  tags = merge(var.tags, {
    Name        = "${var.environment}-redis-cpu-alarm"
    Component   = "cache-monitoring"
    Environment = var.environment
  })
}

resource "aws_cloudwatch_metric_alarm" "redis_memory_utilization" {
  alarm_name          = "${var.environment}-redis-memory-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "DatabaseMemoryUsagePercentage"
  namespace           = "AWS/ElastiCache"
  period              = "300"
  statistic           = "Average"
  threshold           = "85"
  alarm_description   = "This metric monitors redis memory utilization"
  insufficient_data_actions = []

  dimensions = {
    CacheClusterId = var.redis_cluster_id
  }

  tags = merge(var.tags, {
    Name        = "${var.environment}-redis-memory-alarm"
    Component   = "cache-monitoring"
    Environment = var.environment
  })
}

resource "aws_cloudwatch_metric_alarm" "redis_connections" {
  alarm_name          = "${var.environment}-redis-connections"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CurrConnections"
  namespace           = "AWS/ElastiCache"
  period              = "300"
  statistic           = "Average"
  threshold           = "1000"
  alarm_description   = "This metric monitors redis current connections"
  insufficient_data_actions = []

  dimensions = {
    CacheClusterId = var.redis_cluster_id
  }

  tags = merge(var.tags, {
    Name        = "${var.environment}-redis-connections-alarm"
    Component   = "cache-monitoring"
    Environment = var.environment
  })
}

resource "aws_cloudwatch_metric_alarm" "redis_cache_hit_rate" {
  alarm_name          = "${var.environment}-redis-cache-hit-rate"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "CacheHitRate"
  namespace           = "AWS/ElastiCache"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors redis cache hit rate"
  insufficient_data_actions = []

  dimensions = {
    CacheClusterId = var.redis_cluster_id
  }

  tags = merge(var.tags, {
    Name        = "${var.environment}-redis-hit-rate-alarm"
    Component   = "cache-monitoring"
    Environment = var.environment
  })
}

# CloudWatch Dashboard for Redis monitoring
resource "aws_cloudwatch_dashboard" "redis_dashboard" {
  dashboard_name = "${var.environment}-redis-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/ElastiCache", "CPUUtilization", "CacheClusterId", var.redis_cluster_id],
            [".", "DatabaseMemoryUsagePercentage", ".", "."],
          ]
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.name
          title   = "Redis CPU and Memory Utilization"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/ElastiCache", "CurrConnections", "CacheClusterId", var.redis_cluster_id],
            [".", "CacheHitRate", ".", "."],
          ]
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.name
          title   = "Redis Connections and Cache Hit Rate"
          period  = 300
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name        = "${var.environment}-redis-dashboard"
    Component   = "cache-monitoring"
    Environment = var.environment
  })
}

data "aws_region" "current" {}

# Outputs
output "redis_cpu_alarm_arn" {
  description = "ARN of the Redis CPU utilization alarm"
  value       = aws_cloudwatch_metric_alarm.redis_cpu_utilization.arn
}

output "redis_memory_alarm_arn" {
  description = "ARN of the Redis memory utilization alarm"
  value       = aws_cloudwatch_metric_alarm.redis_memory_utilization.arn
}

output "redis_connections_alarm_arn" {
  description = "ARN of the Redis connections alarm"
  value       = aws_cloudwatch_metric_alarm.redis_connections.arn
}

output "redis_cache_hit_rate_alarm_arn" {
  description = "ARN of the Redis cache hit rate alarm"
  value       = aws_cloudwatch_metric_alarm.redis_cache_hit_rate.arn
}

output "redis_dashboard_url" {
  description = "URL of the Redis CloudWatch dashboard"
  value       = "https://${data.aws_region.current.name}.console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.name}#dashboards:name=${aws_cloudwatch_dashboard.redis_dashboard.dashboard_name}"
}