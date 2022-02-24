# Metrics exporter deployment
resource "kubernetes_deployment" "metrics_exporter" {
  metadata {
    name      = local.metrics_exporter_name
    namespace = var.namespace
    labels    = {
      app     = "armonik"
      type    = "monitoring"
      service = "metrics-exporter"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app     = "armonik"
        type    = "monitoring"
        service = "metrics-exporter"
      }
    }
    template {
      metadata {
        name      = "metrics-exporter"
        namespace = var.namespace
        labels    = {
          app     = "armonik"
          type    = "monitoring"
          service = "metrics-exporter"
        }
      }
      spec {
        dynamic toleration {
          for_each = (var.node_selector != {} ? [1] : [])
          content {
            key      = keys(var.node_selector)[0]
            operator = "Equal"
            value    = values(var.node_selector)[0]
            effect   = "NoSchedule"
          }
        }
        container {
          name              = "metrics-exporter"
          image             = "${local.metrics_exporter_image}:${local.metrics_exporter_tag}"
          image_pull_policy = "IfNotPresent"
          port {
            name           = "metrics-exporter"
            container_port = 6443
            protocol       = "TCP"
          }
          liveness_probe {
            http_get {
              path = "/"
              port = "metrics-exporter"
            }
          }
          readiness_probe {
            http_get {
              path = "/"
              port = "metrics-exporter"
            }
          }
          startup_probe {
            http_get {
              path = "/"
              port = "metrics-exporter"
            }
          }
        }
      }
    }
  }
}

# Kubernetes metrics exporter service
resource "kubernetes_service" "metrics_exporter" {
  metadata {
    name      = kubernetes_deployment.metrics_exporter.metadata.0.name
    namespace = kubernetes_deployment.metrics_exporter.metadata.0.namespace
    labels    = {
      app     = kubernetes_deployment.metrics_exporter.metadata.0.labels.app
      type    = kubernetes_deployment.metrics_exporter.metadata.0.labels.type
      service = kubernetes_deployment.metrics_exporter.metadata.0.labels.service
    }
  }
  spec {
    type     = "ClusterIP"
    selector = {
      app     = kubernetes_deployment.metrics_exporter.metadata.0.labels.app
      type    = kubernetes_deployment.metrics_exporter.metadata.0.labels.type
      service = kubernetes_deployment.metrics_exporter.metadata.0.labels.service
    }
    port {
      name        = "metrics-exporter"
      port        = 443
      target_port = 6443
      protocol    = "TCP"
    }
  }
}
