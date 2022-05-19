# Metrics exporter
output "url" {
  description = "URL of Metrics exporter"
  value       = local.url
}

output "port" {
  description = "Port of Metrics exporter"
  value       = local.metrics_exporter_endpoints.port
}

output "host" {
  description = "Host of Metrics exporter"
  value       = local.metrics_exporter_endpoints.ip
}

output "name" {
  description = "Name of Metrics exporter"
  value       = kubernetes_service.metrics_exporter.metadata.0.name
}

output "namespace" {
  description = "Namespace of Metrics exporter"
  value       = var.namespace
}