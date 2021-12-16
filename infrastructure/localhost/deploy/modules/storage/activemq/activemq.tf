# ActiveMQ is deployed as a service in Kubernetes cluster

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
    replicas     = var.activemq.replicas
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
          image = "symptoma/activemq"
          volume_mount {
            name       = "queue-storage-secret-volume"
            mount_path = "/opt/activemq/conf/jetty-realm.properties"
            sub_path   = "jetty-realm.properties"
            read_only  = true
          }
        }
        volume {
          name = "queue-storage-secret-volume"
          secret {
            secret_name = var.activemq.secret
            optional    = false
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
    type     = "ClusterIP"
    selector = {
      app     = kubernetes_deployment.activemq.metadata.0.labels.app
      type    = kubernetes_deployment.activemq.metadata.0.labels.type
      service = kubernetes_deployment.activemq.metadata.0.labels.service
    }
    port {
      name        = "amqp"
      port        = var.activemq.port
      target_port = var.activemq.port
      protocol    = "TCP"
    }
  }
}