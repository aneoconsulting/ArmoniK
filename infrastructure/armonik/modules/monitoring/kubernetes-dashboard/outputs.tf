output "kubernetes_dashboard_url" {
  value = "http://localhost:8001/api/v1/namespaces/${var.namespace}/services/https:${kubernetes_service.kubernetes_dashboard.metadata.0.name}:/proxy/"
}