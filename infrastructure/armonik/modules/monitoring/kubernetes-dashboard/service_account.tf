# Service account
resource "kubernetes_service_account" "kubernetes_dashboard" {
  metadata {
    name      = "kubernetes-dashboard"
    namespace = var.namespace
    labels    = {
      app     = "armonik"
      type    = "service-account"
      service = "kubernetes-dashboard"
    }
  }
}

# Default service account
data "kubernetes_service_account" "kubernetes_dashboard_service_account" {
  metadata {
    name      = kubernetes_service_account.kubernetes_dashboard.metadata.0.name
    namespace = var.namespace
  }
}

