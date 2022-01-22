# Redis is deployed as a service in Kubernetes create-cluster

# Kubernetes Redis deployment
resource "kubernetes_deployment" "redis" {
  metadata {
    name      = "redis"
    namespace = var.namespace
    labels    = {
      app     = "storage"
      type    = "object"
      service = "redis"
    }
  }
  spec {
    replicas = var.redis.replicas
    selector {
      match_labels = {
        app     = "storage"
        type    = "object"
        service = "redis"
      }
    }
    template {
      metadata {
        name   = "redis"
        labels = {
          app     = "storage"
          type    = "object"
          service = "redis"
        }
      }
      spec {
        container {
          name    = "redis"
          image   = "redis:bullseye"
          command = ["redis-server"]
          args    = [
            "--tls-port ${var.redis.port}",
            "--port 0",
            "--tls-cert-file /certificates/cert_file",
            "--tls-key-file /certificates/key_file",
            "--tls-auth-clients no",
            "--requirepass foobared"
          ]
          port {
            container_port = var.redis.port
          }
          volume_mount {
            name       = "redis-storage-secret-volume"
            mount_path = "/certificates"
            read_only  = true
          }
        }
        volume {
          name = "redis-storage-secret-volume"
          secret {
            secret_name = var.kubernetes_secret
            optional    = false
          }
        }
      }
    }
  }
}

# Kubernetes Redis service
resource "kubernetes_service" "redis" {
  metadata {
    name      = kubernetes_deployment.redis.metadata.0.name
    namespace = kubernetes_deployment.redis.metadata.0.namespace
    labels    = {
      app     = kubernetes_deployment.redis.metadata.0.labels.app
      type    = kubernetes_deployment.redis.metadata.0.labels.type
      service = kubernetes_deployment.redis.metadata.0.labels.service
    }
  }
  spec {
    type                    = "NodePort"
    external_traffic_policy = "Local"
    selector                = {
      app     = kubernetes_deployment.redis.metadata.0.labels.app
      type    = kubernetes_deployment.redis.metadata.0.labels.type
      service = kubernetes_deployment.redis.metadata.0.labels.service
    }
    port {
      name        = kubernetes_deployment.redis.metadata.0.name
      port        = var.redis.port
      target_port = var.redis.port
      protocol    = "TCP"
    }
  }
}
