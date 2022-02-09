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
        # Control plane container
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
          env_from {
            config_map_ref {
              name = kubernetes_config_map.core_config.metadata.0.name
            }
          }
          env {
            name = "Amqp__User"
            value_from {
              secret_key_ref {
                key      = var.secrets.activemq_username_key
                name     = var.secrets.activemq_username_secret
                optional = false
              }
            }
          }
          env {
            name = "Amqp__Password"
            value_from {
              secret_key_ref {
                key      = var.secrets.activemq_password_key
                name     = var.secrets.activemq_password_secret
                optional = false
              }
            }
          }
          env {
            name = "Redis__User"
            value_from {
              secret_key_ref {
                key      = var.secrets.redis_username_key
                name     = var.secrets.redis_username_secret
                optional = false
              }
            }
          }
          env {
            name = "Redis__Password"
            value_from {
              secret_key_ref {
                key      = var.secrets.redis_password_key
                name     = var.secrets.redis_password_secret
                optional = false
              }
            }
          }
          env {
            name = "MongoDB__User"
            value_from {
              secret_key_ref {
                key      = var.secrets.mongodb_username_key
                name     = var.secrets.mongodb_username_secret
                optional = false
              }
            }
          }
          env {
            name = "MongoDB__Password"
            value_from {
              secret_key_ref {
                key      = var.secrets.mongodb_password_key
                name     = var.secrets.mongodb_username_secret
                optional = false
              }
            }
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
        # Fluent bit container
        container {
          name              = var.fluent_bit.name
          image             = "${var.fluent_bit.image}:${var.fluent_bit.tag}"
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
            name       = "fluent-bit-configmap"
            mount_path = "/fluent-bit/etc/"
          }
          env {
            name  = "FLUENT_HTTP_SEQ_HOST"
            value = var.seq_endpoints.host
          }
          env {
            name  = "FLUENT_HTTP_SEQ_PORT"
            value = var.seq_endpoints.port
          }
          env {
            name  = "FLUENT_CONTAINER_NAME"
            value = var.fluent_bit.name
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
          name = "fluent-bit-configmap"
          config_map {
            name     = kubernetes_config_map.fluent_bit_config.metadata.0.name
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