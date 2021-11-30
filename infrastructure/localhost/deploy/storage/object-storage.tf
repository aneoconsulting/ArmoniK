# In the local deployment:
# Redis is used as object storage
# Redis is deployed as a service in Kubernetes cluster

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
    replicas = var.object_storage.replicas
    selector {
      match_labels = {
        app     = "storage"
        type    = "object"
        service = "redis"
      }
    }
    template {
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
        container {
          name    = "redis"
          image   = "redis"
          command = [
            "redis-server",
            "--tls-port ${var.object_storage.port}",
            "--port 0",
            "--tls-cert-file /certificates/${var.object_storage.certificates["cert_file"]}",
            "--tls-key-file /certificates/${var.object_storage.certificates["key_file"]}",
            "--tls-ca-cert-file /certificates/${var.object_storage.certificates["ca_cert_file"]}"
          ]
          port {
            container_port = var.object_storage.port
          }
          volume_mount {
            name       = "object-storage-secret-volume"
            mount_path = "/certificates"
            read_only  = true
          }
        }
        volume {
          name = "object-storage-secret-volume"
          secret {
            secret_name = var.object_storage.secret
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
    selector = {
      app     = kubernetes_deployment.redis.metadata.0.labels.app
      type    = kubernetes_deployment.redis.metadata.0.labels.type
      service = kubernetes_deployment.redis.metadata.0.labels.service
    }
    type     = "ClusterIP"
    port {
      name     = kubernetes_deployment.redis.metadata.0.name
      port     = var.object_storage.port
      protocol = "TCP"
    }
  }
}
