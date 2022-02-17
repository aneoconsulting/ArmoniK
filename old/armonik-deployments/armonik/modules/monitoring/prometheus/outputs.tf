# prometheus
output "prometheus" {
  value = kubernetes_service.prometheus
}

output "prometheus_url" {
  value = local.prometheus_url
}