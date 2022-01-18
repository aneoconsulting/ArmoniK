# ArmoniK grafana

# grafana deployment
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
    replicas = 1
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
            container_port = 3000
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
    type     = "LoadBalancer"
    selector = {
      app     = kubernetes_deployment.grafana.metadata.0.labels.app
      type    = kubernetes_deployment.grafana.metadata.0.labels.type
      service = kubernetes_deployment.grafana.metadata.0.labels.service
    }
    port {
      port = 3000
      target_port = 3000
    }
  }
}