# Control plane deployment
resource "kubernetes_deployment" "control_plane" {
  metadata {
    name      = "control-plane"
    namespace = var.namespace
    labels    = {
      app     = "armonik"
      service = "control-plane"
    }
  }
  spec {
    replicas = var.control_plane.replicas
    selector {
      match_labels = {
        app     = "armonik"
        service = "control-plane"
      }
    }
    template {
      metadata {
        name      = "control-plane"
        namespace = var.namespace
        labels    = {
          app     = "armonik"
          service = "control-plane"
        }
      }
      spec {
        dynamic image_pull_secrets {
          for_each = (var.control_plane.image_pull_secrets != "" ? [1] : [])
          content {
            name = var.control_plane.image_pull_secrets
          }
        }
        container {
          name              = "control-plane"
          image             = var.control_plane.tag != "" ? "${var.control_plane.image}:${var.control_plane.tag}" : var.control_plane.image
          image_pull_policy = var.control_plane.image_pull_policy
          resources {
            limits   = {
              cpu    = var.control_plane.limits.cpu
              memory = var.control_plane.limits.memory
            }
            requests = {
              cpu    = var.control_plane.requests.cpu
              memory = var.control_plane.requests.memory
            }
          }
          port {
            name           = "control-port"
            container_port = 80
          }
          volume_mount {
            name       = "control-plane-configmap"
            mount_path = "/app/appsettings.json"
            sub_path   = "appsettings.json"
          }
          dynamic volume_mount {
            for_each = (local.data_type.queue_amqp ? [1] : [])
            content {
              name       = "activemq-secret-volume"
              mount_path = "/amqp"
              read_only  = true
            }
          }
          dynamic volume_mount {
            for_each = (local.data_type.object_redis ? [1] : [])
            content {
              name       = "redis-secret-volume"
              mount_path = "/redis"
              read_only  = true
            }
          }
          dynamic volume_mount {
            for_each = (local.data_type.table_mongodb ? [1] : [])
            content {
              name       = "mongodb-secret-volume"
              mount_path = "/mongodb"
              read_only  = true
            }
          }
        }

        container {
          name              = "fluentbit"
          image             = "fluent/fluent-bit:1.3.11"
          image_pull_policy = "Always"

          volume_mount {
            name       = "varlog"
            mount_path = "/var/log"
          }
          volume_mount {
            name       = "varlibdockercontainers"
            mount_path = "/var/lib/docker/containers"
            read_only  = true
          }
          volume_mount {
            name       = "fluentbit-configmap"
            mount_path = "/fluent-bit/etc/"
          }

          env {
            name  = "FLUENT_GELF_HOST"
            value = "${var.seq_endpoints.host}"
          }
          env {
            name  = "FLUENT_GELF_PORT"
            value = "12201"
          }
          env {
            name  = "FLUENT_GELF_PROTOCOL"
            value = "UDP"
          }
        }

        volume {
          name = "varlog"
          host_path {
            path = "/var/log"
          }
        }
        volume {
          name = "varlibdockercontainers"
          host_path {
            path = "/var/lib/docker/containers"
          }
        }

        volume {
          name = "control-plane-configmap"
          config_map {
            name     = kubernetes_config_map.control_plane_config.metadata.0.name
            optional = false
          }
        }
        volume {
          name = "fluentbit-configmap"
          config_map {
            name     = kubernetes_config_map.fluentbit_config.metadata.0.name
            optional = false
          }
        }
        dynamic volume {
          for_each = (local.data_type.queue_amqp ? [1] : [])
          content {
            name = "activemq-secret-volume"
            secret {
              secret_name = var.storage_endpoint_url.activemq.secret
              optional    = false
            }
          }
        }
        dynamic volume {
          for_each = (local.data_type.object_redis ? [1] : [])
          content {
            name = "redis-secret-volume"
            secret {
              secret_name = var.storage_endpoint_url.redis.secret
              optional    = false
            }
          }
        }
        dynamic volume {
          for_each = (local.data_type.table_mongodb ? [1] : [])
          content {
            name = "mongodb-secret-volume"
            secret {
              secret_name = var.storage_endpoint_url.mongodb.secret
              optional    = false
            }
          }
        }
      }
    }
  }
}

# Control plane service
resource "kubernetes_service" "control_plane" {
  metadata {
    name      = kubernetes_deployment.control_plane.metadata.0.name
    namespace = kubernetes_deployment.control_plane.metadata.0.namespace
    labels    = {
      app     = kubernetes_deployment.control_plane.metadata.0.labels.app
      service = kubernetes_deployment.control_plane.metadata.0.labels.service
    }
  }
  spec {
    type     = "LoadBalancer"
    selector = {
      app     = kubernetes_deployment.control_plane.metadata.0.labels.app
      service = kubernetes_deployment.control_plane.metadata.0.labels.service
    }
    port {
      name        = kubernetes_deployment.control_plane.spec.0.template.0.spec.0.container.0.port.0.name
      port        = var.control_plane.port
      target_port = kubernetes_deployment.control_plane.spec.0.template.0.spec.0.container.0.port.0.container_port
      protocol    = "TCP"
    }
  }
}