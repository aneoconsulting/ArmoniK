# grafana
output "url" {
  description = "URL of Grafana"
  value       = local.grafana_url
}

output "port" {
  description = "Port of Grafana"
  value       = local.grafana_endpoints.port
}

output "host" {
  description = "Host of Grafana"
  value       = local.grafana_endpoints.ip
}