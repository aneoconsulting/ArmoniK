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
          volume_mount {
            name       = "polling-agent-configmap"
            mount_path = "/app/appsettings.json"
            sub_path   = "appsettings.json"
          }
          volume_mount {
            name       = "cache-volume"
            mount_path = "/cache"
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
        # Fluent-bit container
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
            volume_mount {
              name       = "worker-configmap"
              mount_path = "/app/appsettings.json"
              sub_path   = "appsettings.json"
            }
            volume_mount {
              name       = "cache-volume"
              mount_path = "/cache"
            }
            volume_mount {
              name       = "shared-volume"
              mount_path = "/data"
              read_only  = true
            }
            dynamic volume_mount {
              for_each = (local.data_type.external_redis ? [1] : [])
              content {
                name       = "external-redis-secret-volume"
                mount_path = "/redis"
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
          name = "polling-agent-configmap"
          config_map {
            name     = kubernetes_config_map.polling_agent_config.metadata.0.name
            optional = false
          }
        }
        volume {
          name = "worker-configmap"
          config_map {
            name     = kubernetes_config_map.worker_config.metadata.0.name
            optional = false
          }
        }
        volume {
          name = "cache-volume"
          empty_dir {}
        }
        dynamic volume {
          for_each = (local.data_type.shared_host_path ? [1] : [])
          content {
            name = "shared-volume"
            host_path {
              path = var.storage_endpoint_url.shared.path
              type = "Directory"
            }
          }
        }
        dynamic volume {
          for_each = (local.data_type.shared_nfs ? [1] : [])
          content {
            name = "shared-volume"
            nfs {
              path      = var.storage_endpoint_url.shared.path
              server    = var.storage_endpoint_url.shared.host
              read_only = true
            }
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
        dynamic volume {
          for_each = (local.data_type.external_redis ? [1] : [])
          content {
            name = "external-redis-secret-volume"
            secret {
              secret_name = var.storage_endpoint_url.external.secret
              optional    = false
            }
          }
        }
      }
    }
  }
}