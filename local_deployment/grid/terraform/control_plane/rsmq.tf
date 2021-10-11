resource "kubernetes_deployment" "rsmq" {
  metadata {
    name      = "rsmq"
    labels = {
      app = "local-scheduler"
      service = "rsmq"
    }
  }
  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "local-scheduler"
        service = "rsmq"
      }
    }

    template {
      metadata {
        labels = {
          app = "local-scheduler"
          service = "rsmq"
        }
      }

      spec {
        container {
          image   = "redis"
          name    = "rsmq"
          command = ["redis-server", "--tls-port ${var.rsmq_port}", "--port 0", "--tls-cert-file /redis_certificates/redis.crt", "--tls-key-file /redis_certificates/redis.key", "--tls-ca-cert-file /redis_certificates/ca.crt"]

          port {
            container_port = var.rsmq_port
          }

          volume_mount {
            name       = "rsmq-vol"
            mount_path = "/redis_certificates"
          }
        }

        volume {
          name = "rsmq-vol"
          host_path {
            path = var.certificates_dir_path
            type = ""
          }
        }
      }
    }
  }
}


resource "kubernetes_service" "rsmq" {
  metadata {
    name = "rsmq"
  }

  spec {
    selector = {
      app     = kubernetes_deployment.rsmq.metadata.0.labels.app
      service = kubernetes_deployment.rsmq.metadata.0.labels.service
    }
    type = "LoadBalancer"
    port {
      protocol = "TCP"
      port = var.rsmq_port
      name = "rsmq"
    }
  }
}