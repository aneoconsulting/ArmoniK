# Grafana deployment
resource "kubernetes_deployment" "grafana" {
  metadata {
    name      = "grafana"
    namespace = var.namespace
    labels    = {
      app     = "armonik"
      type    = "logs"
      service = "grafana"
    }
  }
  spec {
    replicas = var.grafana.replicas
    selector {
      match_labels = {
        app     = "armonik"
        type    = "logs"
        service = "grafana"
      }
    }
    template {
      metadata {
        name      = "grafana"
        namespace = var.namespace
        labels    = {
          app     = "armonik"
          type    = "logs"
          service = "grafana"
        }
      }
      spec {
        container {
          name              = "grafana"
          image             = "grafana/grafana:latest"
          image_pull_policy = "IfNotPresent"
          env {
            name  = "discovery.type"
            value = "single-node"
          }
          port {
            name           = var.grafana.port.name
            container_port = var.grafana.port.target_port
            protocol       = var.grafana.port.protocol
          }
        }
      }
    }
  }
}

# Kubernetes grafana service
resource "kubernetes_service" "grafana" {
  metadata {
    name      = kubernetes_deployment.grafana.metadata.0.name
    namespace = kubernetes_deployment.grafana.metadata.0.namespace
    labels    = {
      app     = kubernetes_deployment.grafana.metadata.0.labels.app
      type    = kubernetes_deployment.grafana.metadata.0.labels.type
      service = kubernetes_deployment.grafana.metadata.0.labels.service
    }
  }
  spec {
    type                    = "NodePort"
    external_traffic_policy = "Local"
    selector                = {
      app     = kubernetes_deployment.grafana.metadata.0.labels.app
      type    = kubernetes_deployment.grafana.metadata.0.labels.type
      service = kubernetes_deployment.grafana.metadata.0.labels.service
    }
    port {
      name        = var.grafana.port.name
      port        = var.grafana.port.port
      target_port = var.grafana.port.target_port
      protocol    = var.grafana.port.protocol
    }
  }
}