resource "kubernetes_deployment" "redis" {
  metadata {
    name      = "redis"
    labels = {
      app = "local-scheduler"
      service = "redis"
    }
  }
  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "local-scheduler"
        service = "redis"
      }
    }
    
    template {
      metadata {
        labels = {
          app = "local-scheduler"
          service = "redis"
        }
      }

      spec {
        container {
          image   = "redis"
          name    = "redis"
          command = ["redis-server", "--tls-port ${var.redis_port}", "--port 0", "--tls-cert-file /data/redis.crt", "--tls-key-file /data/redis.key", "--tls-ca-cert-file /data/ca.crt"]

          port {
            container_port = var.redis_port
          }

          volume_mount {
            name       = "redis-vol"
            mount_path = "/data"
          }
        }

        volume {
          name = "redis-vol"
          host_path {
            path = var.certificates_dir_path
            type = ""
          }
        }
      }
    }
  }
}


resource "kubernetes_service" "redis" {
  metadata {
    name = "redis"
  }

  spec {
    selector = {
      app     = kubernetes_deployment.redis.metadata.0.labels.app
      service = kubernetes_deployment.redis.metadata.0.labels.service
    }
    type = "LoadBalancer"
    port {
      protocol = "TCP"
      port = var.redis_port
      name = "redis"
    }
  }
}