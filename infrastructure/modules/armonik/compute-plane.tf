# Agent deployment
resource "kubernetes_deployment" "compute_plane" {
  count = (var.compute_plane.max_priority == 0 ? 1 : var.compute_plane.max_priority)
  metadata {
    name      = "compute-plane-${count.index}"
    namespace = var.namespace
    labels    = {
      app     = "armonik"
      service = "compute-plane"
    }
  }
  spec {
    replicas = var.compute_plane.replicas
    selector {
      match_labels = {
        app     = "armonik"
        service = "compute-plane"
      }
    }
    template {
      metadata {
        name      = "compute-plane-${count.index}"
        namespace = var.namespace
        labels    = {
          app     = "armonik"
          service = "compute-plane"
        }
      }
      spec {
        termination_grace_period_seconds = var.compute_plane.termination_grace_period_seconds
        share_process_namespace          = true
        security_context {}
        dynamic image_pull_secrets {
          for_each = (var.compute_plane.image_pull_secrets != "" ? [1] : [])
          content {
            name = var.compute_plane.image_pull_secrets
          }
        }
        # Polling agent container
        container {
          name              = "polling-agent"
          image             = var.compute_plane.polling_agent.tag != "" ? "${var.compute_plane.polling_agent.image}:${var.compute_plane.polling_agent.tag}" : var.compute_plane.polling_agent.image
          image_pull_policy = var.compute_plane.polling_agent.image_pull_policy
          security_context {
            capabilities {
              drop = ["SYS_PTRACE"]
            }
          }
          resources {
            limits   = {
              cpu    = var.compute_plane.polling_agent.limits.cpu
              memory = var.compute_plane.polling_agent.limits.memory
            }
            requests = {
              cpu    = var.compute_plane.polling_agent.requests.cpu
              memory = var.compute_plane.polling_agent.requests.memory
            }
          }
          env_from {
            config_map_ref {
              name = kubernetes_config_map.core_config.metadata.0.name
            }
          }
          dynamic env {
            for_each = (local.activemq_credentials_secret != "" ? [1] : [])
            content {
              name = "Amqp__User"
              value_from {
                secret_key_ref {
                  key      = local.activemq_credentials_username_key
                  name     = local.activemq_credentials_secret
                  optional = false
                }
              }
            }
          }
          dynamic env {
            for_each = (local.activemq_credentials_secret != "" ? [1] : [])
            content {
              name = "Amqp__Password"
              value_from {
                secret_key_ref {
                  key      = local.activemq_credentials_password_key
                  name     = local.activemq_credentials_secret
                  optional = false
                }
              }
            }
          }
          dynamic env {
            for_each = (local.redis_credentials_secret != "" ? [1] : [])
            content {
              name = "Redis__User"
              value_from {
                secret_key_ref {
                  key      = local.redis_credentials_username_key
                  name     = local.redis_credentials_secret
                  optional = false
                }
              }
            }
          }
          dynamic env {
            for_each = (local.redis_credentials_secret != "" ? [1] : [])
            content {
              name = "Redis__Password"
              value_from {
                secret_key_ref {
                  key      = local.redis_credentials_password_key
                  name     = local.redis_credentials_secret
                  optional = false
                }
              }
            }
          }
          dynamic env {
            for_each = (local.mongodb_credentials_secret != "" ? [1] : [])
            content {
              name = "MongoDB__User"
              value_from {
                secret_key_ref {
                  key      = local.mongodb_credentials_username_key
                  name     = local.mongodb_credentials_secret
                  optional = false
                }
              }
            }
          }
          dynamic env {
            for_each = (local.mongodb_credentials_secret != "" ? [1] : [])
            content {
              name = "MongoDB__Password"
              value_from {
                secret_key_ref {
                  key      = local.mongodb_credentials_password_key
                  name     = local.mongodb_credentials_secret
                  optional = false
                }
              }
            }
          }
          volume_mount {
            name       = "cache-volume"
            mount_path = "/cache"
          }
          dynamic volume_mount {
            for_each = (local.activemq_certificates_secret != "" ? [1] : [])
            content {
              name       = "activemq-secret-volume"
              mount_path = "/amqp"
              read_only  = true
            }
          }
          dynamic volume_mount {
            for_each = (local.redis_certificates_secret != "" ? [1] : [])
            content {
              name       = "redis-secret-volume"
              mount_path = "/redis"
              read_only  = true
            }
          }
          dynamic volume_mount {
            for_each = (local.mongodb_certificates_secret != "" ? [1] : [])
            content {
              name       = "mongodb-secret-volume"
              mount_path = "/mongodb"
              read_only  = true
            }
          }
        }
        # Fluent-bit container
        container {
          name              = "fluent-bit"
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
            value = "fluent-bit"
          }
        }
        # Containers of worker
        dynamic container {
          iterator = worker
          for_each = var.compute_plane.worker
          content {
            name              = "${worker.value.name}-${worker.key}"
            image             = worker.value.tag != "" ? "${worker.value.image}:${worker.value.tag}" : worker.value.image
            image_pull_policy = worker.value.image_pull_policy
            port {
              container_port = worker.value.port
            }
            resources {
              limits   = {
                cpu    = worker.value.limits.cpu
                memory = worker.value.limits.memory
              }
              requests = {
                cpu    = worker.value.requests.cpu
                memory = worker.value.requests.memory
              }
            }
            env_from {
              config_map_ref {
                name = kubernetes_config_map.worker_config.metadata.0.name
              }
            }
            volume_mount {
              name       = "cache-volume"
              mount_path = "/cache"
            }
            dynamic volume_mount {
              for_each = (local.check_file_storage_type == "FS" ? [1] : [])
              content {
                name       = "shared-volume"
                mount_path = "/data"
                read_only  = true
              }
            }
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
        volume {
          name = "cache-volume"
          empty_dir {}
        }
        dynamic volume {
          for_each = (local.lower_file_storage_type == "nfs" ? [1] : [])
          content {
            name = "shared-volume"
            nfs {
              path      = local.host_path
              server    = local.file_server_ip
              read_only = true
            }
          }
        }
        dynamic volume {
          for_each = (local.lower_file_storage_type == "hostpath" ? [1] : [])
          content {
            name = "shared-volume"
            host_path {
              path = local.host_path
              type = "Directory"
            }
          }
        }
        dynamic volume {
          for_each = (local.activemq_certificates_secret != "" ? [1] : [])
          content {
            name = "activemq-secret-volume"
            secret {
              secret_name = local.activemq_certificates_secret
              optional    = false
            }
          }
        }
        dynamic volume {
          for_each = (local.redis_certificates_secret != "" ? [1] : [])
          content {
            name = "redis-secret-volume"
            secret {
              secret_name = local.redis_certificates_secret
              optional    = false
            }
          }
        }
        dynamic volume {
          for_each = (local.mongodb_certificates_secret != "" ? [1] : [])
          content {
            name = "mongodb-secret-volume"
            secret {
              secret_name = local.mongodb_certificates_secret
              optional    = false
            }
          }
        }
      }
    }
  }
}