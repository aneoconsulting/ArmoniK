output "application_cloudwatch_log_group" {
  description = "CloudWatch log group for applications"
  value       = module.application_logs.name
}

output "dataplane_cloudwatch_log_group" {
  description = "CloudWatch log group for dataplane"
  value       = module.dataplane_logs.name
}

output "host_cloudwatch_log_group" {
  description = "CloudWatch log group for hosts"
  value       = module.host_logs.name
}