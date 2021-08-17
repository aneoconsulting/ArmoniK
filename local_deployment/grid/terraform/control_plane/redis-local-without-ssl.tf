resource "kubernetes_deployment" "redis-without-ssl" {
  metadata {
    name      = "redis-without-ssl"
    labels = {
      app = "local-scheduler"
      service = "redis-without-ssl"
    }
  }
  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "local-scheduler"
        service = "redis-without-ssl"
      }
    }

    template {
      metadata {
        labels = {
          app = "local-scheduler"
          service = "redis-without-ssl"
        }
      }

      spec {
        container {
          image   = "redis"
          name    = "redis-without-ssl"
          command = ["redis-server", "--port ${var.redis_port_without_ssl}"]

          port {
            container_port = var.redis_port_without_ssl
          }

          volume_mount {
            name       = "redis-vol-without-ssl"
            mount_path = "/data"
          }
        }

        volume {
          name = "redis-vol-without-ssl"
        }
      }
    }
  }
}


resource "kubernetes_service" "redis-without-ssl" {
  metadata {
    name = "redis-without-ssl"
  }

  spec {
    selector = {
      app     = kubernetes_deployment.redis-without-ssl.metadata.0.labels.app
      service = kubernetes_deployment.redis-without-ssl.metadata.0.labels.service
    }
    type = "LoadBalancer"
    port {
      protocol = "TCP"
      port = var.redis_port_without_ssl
      name = "redis-without-ssl"
    }
  }
}