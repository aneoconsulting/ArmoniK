# prometheus deployment
resource "kubernetes_deployment" "prometheus" {
  metadata {
    name      = "prometheus"
    namespace = var.namespace
    labels    = {
      app     = "armonik"
      type    = "logs"
      service = "prometheus"
    }
  }
  spec {
    replicas = var.prometheus.replicas
    selector {
      match_labels = {
        app     = "armonik"
        type    = "logs"
        service = "prometheus"
      }
    }
    template {
      metadata {
        name      = "prometheus"
        namespace = var.namespace
        labels    = {
          app     = "armonik"
          type    = "logs"
          service = "prometheus"
        }
      }
      spec {
        container {
          name              = "prometheus"
          image             = "prom/prometheus:latest"
          image_pull_policy = "IfNotPresent"
          env {
            name  = "discovery.type"
            value = "single-node"
          }
          port {
            name           = var.prometheus.port.name
            container_port = var.prometheus.port.target_port
            protocol       = var.prometheus.port.protocol
          }
        }
      }
    }
  }
}

# Kubernetes prometheus service
resource "kubernetes_service" "prometheus" {
  metadata {
    name      = kubernetes_deployment.prometheus.metadata.0.name
    namespace = kubernetes_deployment.prometheus.metadata.0.namespace
    labels    = {
      app     = kubernetes_deployment.prometheus.metadata.0.labels.app
      type    = kubernetes_deployment.prometheus.metadata.0.labels.type
      service = kubernetes_deployment.prometheus.metadata.0.labels.service
    }
  }
  spec {
    type                    = "LoadBalancer"
    selector                = {
      app     = kubernetes_deployment.prometheus.metadata.0.labels.app
      type    = kubernetes_deployment.prometheus.metadata.0.labels.type
      service = kubernetes_deployment.prometheus.metadata.0.labels.service
    }
    port {
      name        = var.prometheus.port.name
      port        = var.prometheus.port.port
      target_port = var.prometheus.port.target_port
      protocol    = var.prometheus.port.protocol
    }
  }
}