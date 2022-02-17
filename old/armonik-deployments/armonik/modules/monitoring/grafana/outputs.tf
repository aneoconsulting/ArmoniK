# Grafana
output "grafana" {
  value = kubernetes_service.grafana
}

output "grafana_url" {
  value = local.grafana_url
}