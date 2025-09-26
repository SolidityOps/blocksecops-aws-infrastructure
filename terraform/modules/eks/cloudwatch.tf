# CloudWatch Configuration for EKS Cluster Monitoring
# This file configures comprehensive CloudWatch monitoring and logging for EKS clusters

# Additional CloudWatch Log Groups for different components
resource "aws_cloudwatch_log_group" "node_group" {
  name              = "/aws/eks/${var.cluster_name}/node-group"
  retention_in_days = var.cloudwatch_log_retention_days

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-node-group-logs"
    Type = "EKS-NodeGroup-CloudWatch-LogGroup"
  })
}

resource "aws_cloudwatch_log_group" "cluster_autoscaler" {
  name              = "/aws/eks/${var.cluster_name}/cluster-autoscaler"
  retention_in_days = var.cloudwatch_log_retention_days

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-cluster-autoscaler-logs"
    Type = "EKS-ClusterAutoscaler-CloudWatch-LogGroup"
  })
}

# CloudWatch Metric Filters for important events
resource "aws_cloudwatch_log_metric_filter" "cluster_errors" {
  name           = "${var.cluster_name}-cluster-errors"
  log_group_name = aws_cloudwatch_log_group.cluster.name
  pattern        = "ERROR"

  metric_transformation {
    name      = "ClusterErrors"
    namespace = "EKS/Cluster/${var.cluster_name}"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "authentication_failures" {
  name           = "${var.cluster_name}-auth-failures"
  log_group_name = aws_cloudwatch_log_group.cluster.name
  pattern        = "authentication failed"

  metric_transformation {
    name      = "AuthenticationFailures"
    namespace = "EKS/Security/${var.cluster_name}"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "unauthorized_api_calls" {
  name           = "${var.cluster_name}-unauthorized-calls"
  log_group_name = aws_cloudwatch_log_group.cluster.name
  pattern        = "Forbidden"

  metric_transformation {
    name      = "UnauthorizedAPICalls"
    namespace = "EKS/Security/${var.cluster_name}"
    value     = "1"
  }
}

# CloudWatch Alarms for cluster monitoring
resource "aws_cloudwatch_metric_alarm" "cluster_errors" {
  alarm_name          = "${var.cluster_name}-cluster-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ClusterErrors"
  namespace           = "EKS/Cluster/${var.cluster_name}"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "This metric monitors cluster errors"
  alarm_actions       = var.sns_topic_arn != "" ? [var.sns_topic_arn] : []

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "authentication_failures" {
  alarm_name          = "${var.cluster_name}-auth-failures"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "AuthenticationFailures"
  namespace           = "EKS/Security/${var.cluster_name}"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "This metric monitors authentication failures"
  alarm_actions       = var.sns_topic_arn != "" ? [var.sns_topic_arn] : []

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "unauthorized_api_calls" {
  alarm_name          = "${var.cluster_name}-unauthorized-calls"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "UnauthorizedAPICalls"
  namespace           = "EKS/Security/${var.cluster_name}"
  period              = "300"
  statistic           = "Sum"
  threshold           = "3"
  alarm_description   = "This metric monitors unauthorized API calls"
  alarm_actions       = var.sns_topic_arn != "" ? [var.sns_topic_arn] : []

  tags = var.tags
}

# Node Group CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "node_group_cpu_utilization" {
  alarm_name          = "${var.cluster_name}-${var.node_group_name}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors node group CPU utilization"
  alarm_actions       = var.sns_topic_arn != "" ? [var.sns_topic_arn] : []

  dimensions = {
    AutoScalingGroupName = aws_eks_node_group.main.resources[0].autoscaling_groups[0].name
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "node_group_memory_utilization" {
  count = var.enable_container_insights ? 1 : 0

  alarm_name          = "${var.cluster_name}-${var.node_group_name}-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "node_memory_utilization"
  namespace           = "ContainerInsights"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors node group memory utilization"
  alarm_actions       = var.sns_topic_arn != "" ? [var.sns_topic_arn] : []

  dimensions = {
    ClusterName = aws_eks_cluster.main.name
    NodeName    = "*"
  }

  tags = var.tags
}

# Container Insights for enhanced monitoring
resource "aws_cloudwatch_log_group" "container_insights_application" {
  count = var.enable_container_insights ? 1 : 0

  name              = "/aws/containerinsights/${aws_eks_cluster.main.name}/application"
  retention_in_days = var.cloudwatch_log_retention_days

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-container-insights-application"
    Type = "EKS-ContainerInsights-LogGroup"
  })
}

resource "aws_cloudwatch_log_group" "container_insights_dataplane" {
  count = var.enable_container_insights ? 1 : 0

  name              = "/aws/containerinsights/${aws_eks_cluster.main.name}/dataplane"
  retention_in_days = var.cloudwatch_log_retention_days

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-container-insights-dataplane"
    Type = "EKS-ContainerInsights-LogGroup"
  })
}

resource "aws_cloudwatch_log_group" "container_insights_host" {
  count = var.enable_container_insights ? 1 : 0

  name              = "/aws/containerinsights/${aws_eks_cluster.main.name}/host"
  retention_in_days = var.cloudwatch_log_retention_days

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-container-insights-host"
    Type = "EKS-ContainerInsights-LogGroup"
  })
}

resource "aws_cloudwatch_log_group" "container_insights_performance" {
  count = var.enable_container_insights ? 1 : 0

  name              = "/aws/containerinsights/${aws_eks_cluster.main.name}/performance"
  retention_in_days = var.cloudwatch_log_retention_days

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-container-insights-performance"
    Type = "EKS-ContainerInsights-LogGroup"
  })
}

# Dashboard for EKS monitoring
resource "aws_cloudwatch_dashboard" "eks_cluster" {
  dashboard_name = "${var.cluster_name}-dashboard"

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
            ["EKS/Cluster/${var.cluster_name}", "ClusterErrors"],
            ["EKS/Security/${var.cluster_name}", "AuthenticationFailures"],
            ["EKS/Security/${var.cluster_name}", "UnauthorizedAPICalls"]
          ]
          period = 300
          stat   = "Sum"
          region = data.aws_region.current.name
          title  = "EKS Cluster Security Metrics"
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
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", aws_eks_node_group.main.resources[0].autoscaling_groups[0].name]
          ]
          period = 300
          stat   = "Average"
          region = data.aws_region.current.name
          title  = "Node Group CPU Utilization"
        }
      }
    ]
  })
}