# Outputs for Monitoring Module

output "vpc_flow_logs_s3_bucket_name" {
  description = "Name of the VPC Flow Logs S3 bucket"
  value       = aws_s3_bucket.vpc_flow_logs.bucket
}

output "vpc_flow_logs_s3_bucket_arn" {
  description = "ARN of the VPC Flow Logs S3 bucket"
  value       = aws_s3_bucket.vpc_flow_logs.arn
}

output "vpc_flow_log_id" {
  description = "ID of the VPC Flow Log"
  value       = aws_flow_log.vpc.id
}