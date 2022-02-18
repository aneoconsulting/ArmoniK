output "name" {
  description = "CloudWatch log group name"
  value       = aws_cloudwatch_log_group.log_group.name
}

output "arn" {
  description = "CloudWatch log group ARN"
  value       = aws_cloudwatch_log_group.log_group.arn
}

