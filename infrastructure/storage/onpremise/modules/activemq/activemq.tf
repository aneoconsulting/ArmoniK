# ActiveMQ is deployed as a service in Kubernetes create-cluster

# Kubernetes ActiveMQ deployment
resource "kubernetes_deployment" "activemq" {
  metadata {
    name      = "activemq"
    namespace = var.namespace
    labels    = {
      app     = "storage"
      type    = "queue"
      service = "activemq"
    }
  }
  spec {
    replicas = var.activemq.replicas
    selector {
      match_labels = {
        app     = "storage"
        type    = "queue"
        service = "activemq"
      }
    }
    template {
      metadata {
        name   = "activemq"
        labels = {
          app     = "storage"
          type    = "queue"
          service = "activemq"
        }
      }
      spec {
        container {
          name  = "activemq"
          image = "symptoma/activemq:5.16.3"
          volume_mount {
            name       = "activemq-storage-secret-volume"
            mount_path = "/credentials/"
            read_only  = true
          }
          volume_mount {
            name       = "activemq-jetty-xml"
            mount_path = "/opt/activemq/conf/"
            read_only  = true
          }
          dynamic port {
            for_each = var.activemq.port
            content {
              name           = port.value.name
              container_port = port.value.target_port
              protocol       = port.value.protocol
            }
          }
        }
        volume {
          name = "activemq-storage-secret-volume"
          secret {
            secret_name = var.kubernetes_secret
            optional    = false
          }
        }
        volume {
          name = "activemq-jetty-xml"
          config_map {
            name     = kubernetes_config_map.activemq_configs.metadata.0.name
            optional = false
          }
        }
      }
    }
  }
}

# Kubernetes ActiveMQ service
resource "kubernetes_service" "activemq" {
  metadata {
    name      = kubernetes_deployment.activemq.metadata.0.name
    namespace = kubernetes_deployment.activemq.metadata.0.namespace
    labels    = {
      app     = kubernetes_deployment.activemq.metadata.0.labels.app
      type    = kubernetes_deployment.activemq.metadata.0.labels.type
      service = kubernetes_deployment.activemq.metadata.0.labels.service
    }
  }
  spec {
    type                    = "NodePort"
    external_traffic_policy = "Local"
    selector                = {
      app     = kubernetes_deployment.activemq.metadata.0.labels.app
      type    = kubernetes_deployment.activemq.metadata.0.labels.type
      service = kubernetes_deployment.activemq.metadata.0.labels.service
    }
    dynamic port {
      for_each = var.activemq.port
      content {
        name        = port.value.name
        port        = port.value.port
        target_port = port.value.target_port
        protocol    = port.value.protocol
      }
    }
  }
}