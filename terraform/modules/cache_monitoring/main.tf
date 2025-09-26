# CloudWatch Alarms for ElastiCache Redis
resource "aws_cloudwatch_metric_alarm" "redis_cpu_utilization" {
  alarm_name                = "${var.environment}-redis-cpu-utilization"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = var.alarm_evaluation_periods
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/ElastiCache"
  period                    = var.alarm_period
  statistic                 = "Average"
  threshold                 = var.cpu_threshold
  alarm_description         = "This metric monitors redis cpu utilization"
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
  alarm_name                = "${var.environment}-redis-memory-utilization"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = var.alarm_evaluation_periods
  metric_name               = "DatabaseMemoryUsagePercentage"
  namespace                 = "AWS/ElastiCache"
  period                    = var.alarm_period
  statistic                 = "Average"
  threshold                 = var.memory_threshold
  alarm_description         = "This metric monitors redis memory utilization"
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
  alarm_name                = "${var.environment}-redis-connections"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = var.alarm_evaluation_periods
  metric_name               = "CurrConnections"
  namespace                 = "AWS/ElastiCache"
  period                    = var.alarm_period
  statistic                 = "Average"
  threshold                 = var.connections_threshold
  alarm_description         = "This metric monitors redis current connections"
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
  alarm_name                = "${var.environment}-redis-cache-hit-rate"
  comparison_operator       = "LessThanThreshold"
  evaluation_periods        = var.alarm_evaluation_periods
  metric_name               = "CacheHitRate"
  namespace                 = "AWS/ElastiCache"
  period                    = var.alarm_period
  statistic                 = "Average"
  threshold                 = var.cache_hit_rate_threshold
  alarm_description         = "This metric monitors redis cache hit rate"
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
          period  = var.alarm_period
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
          period  = var.alarm_period
        }
      }
    ]
  })
}

data "aws_region" "current" {}