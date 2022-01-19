resource "kubernetes_secret" "kubernetes_dashboard_certs" {
  metadata {
    name      = "kubernetes-dashboard-certs"
    namespace = var.namespace
    labels    = {
      app     = "armonik"
      type    = "secret"
      service = "kubernetes-dashboard"
    }
  }
  type = "Opaque"
}

resource "kubernetes_secret" "kubernetes_dashboard_csrf" {
  metadata {
    name      = "kubernetes-dashboard-csrf"
    namespace = var.namespace
    labels    = {
      app  = "armonik"
      type = "secret"
      service : "kubernetes-dashboard"
    }
  }
  type = "Opaque"
  data = {
    csrf = ""
  }
}

resource "kubernetes_secret" "kubernetes_dashboard_key_holder" {
  metadata {
    name      = "kubernetes-dashboard-key-holder"
    namespace = var.namespace
    labels    = {
      app     = "armonik"
      type    = "secret"
      service = "kubernetes-dashboard"
    }
  }
  type = "Opaque"
}
