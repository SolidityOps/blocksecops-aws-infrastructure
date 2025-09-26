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