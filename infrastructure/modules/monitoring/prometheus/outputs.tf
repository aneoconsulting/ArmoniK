# prometheus
output "url" {
  description = "URL of prometheus"
  value = local.prometheus_url
}

output "port" {
  description = "Port of prometheus"
  value = local.prometheus_endpoints.port
}

output "host" {
  description = "Host of prometheus"
  value = local.prometheus_endpoints.ip
}