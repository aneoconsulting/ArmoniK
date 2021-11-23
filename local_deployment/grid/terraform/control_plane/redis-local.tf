resource "kubernetes_deployment" "redis" {
  metadata {
    name   = "redis"
    labels = {
      app     = "local-scheduler"
      service = "redis"
    }
  }
  spec {
    replicas = 1

    selector {
      match_labels = {
        app     = "local-scheduler"
        service = "redis"
      }
    }

    template {
      metadata {
        labels = {
          app     = "local-scheduler"
          service = "redis"
        }
      }

      spec {
        container {
          image   = "redis"
          name    = "redis"
          command = [
            "redis-server",
            "--tls-port ${var.redis_port}",
            "--port 0",
            "--tls-cert-file ${var.redis_cert_file}",
            "--tls-key-file ${var.redis_key_file}",
            "--tls-ca-cert-file ${var.redis_ca_cert}"
          ]

          port {
            container_port = var.redis_port
          }

          volume_mount {
            name       = "redis-secrets-volume"
            mount_path = "/redis_certificates"
            read_only = true
          }
        }

        volume {
          name = "redis-secrets-volume"
          secret {
            secret_name = var.redis_secrets
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
    type     = "LoadBalancer"
    port {
      protocol = "TCP"
      port     = var.redis_port
      name     = "redis"
    }
  }
}