resource "kubernetes_api_service" "api_service" {
  metadata {
    name   = var.api_service.name
    labels = {
      app     = "armonik"
      type    = "monitoring"
      service = "api-service"
    }
  }
  spec {
    group                    = local.api_service_group
    group_priority_minimum   = local.api_service_group_priority_minimum
    version                  = local.api_service_version
    version_priority         = local.api_service_version_priority
    insecure_skip_tls_verify = local.api_service_insecure_skip_tls_verify
    service {
      name      = kubernetes_service.metrics_exporter.metadata.0.name
      namespace = kubernetes_service.metrics_exporter.metadata.0.namespace
      port      = kubernetes_service.metrics_exporter.spec.0.port.0.port
    }
  }
}