# Partition metrics exporter
output "url" {
  description = "URL of partition metrics exporter"
  value       = local.url
}

output "port" {
  description = "Port of partition metrics exporter"
  value       = local.partition_metrics_exporter_endpoints.port
}

output "host" {
  description = "Host of partition metrics exporter"
  value       = local.partition_metrics_exporter_endpoints.ip
}

output "name" {
  description = "Name of partition metrics exporter"
  value       = kubernetes_service.partition_metrics_exporter.metadata.0.name
}

output "namespace" {
  description = "Namespace of partition metrics exporter"
  value       = var.namespace
}