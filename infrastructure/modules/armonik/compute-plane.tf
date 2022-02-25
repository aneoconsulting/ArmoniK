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
        dynamic toleration {
          for_each = (local.compute_plane_node_selector != {} ? [
          for index in range(0, length(local.compute_plane_node_selector_keys)) : {
            key   = local.compute_plane_node_selector_keys[index]
            value = local.compute_plane_node_selector_values[index]
          }
          ] : [])
          content {
            key      = toleration.value.key
            operator = "Equal"
            value    = toleration.value.value
            effect   = "NoSchedule"
          }
        }
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
        # Fluent-bit container
        dynamic container {
          for_each = (!local.fluent_bit_is_daemonset ? [1] : [])
          content {
            name              = local.fluent_bit_container_name
            image             = "${local.fluent_bit_image}:${local.fluent_bit_tag}"
            image_pull_policy = "Always"
            env_from {
              config_map_ref {
                name = local.fluent_bit_envvars_configmap
              }
            }
            resources {
              limits   = {
                memory = "200Mi"
              }
              requests = {
                cpu    = "500m"
                memory = "100Mi"
              }
            }
            # Please don't change below read-only permissions
            volume_mount {
              name       = "fluentbitstate"
              mount_path = "/var/fluent-bit/state"
            }
            volume_mount {
              name       = "varlog"
              mount_path = "/var/log"
              read_only  = true
            }
            volume_mount {
              name       = "varlibdockercontainers"
              mount_path = "/var/lib/docker/containers"
              read_only  = true
            }
            volume_mount {
              name       = "runlogjournal"
              mount_path = "/run/log/journal"
              read_only  = true
            }
            volume_mount {
              name       = "dmesg"
              mount_path = "/var/log/dmesg"
              read_only  = true
            }
            volume_mount {
              name       = "fluent-bit-config"
              mount_path = "/fluent-bit/etc/"
            }
          }
        }
        dynamic volume {
          for_each = (!local.fluent_bit_is_daemonset ? [1] : [])
          content {
            name = "fluentbitstate"
            host_path {
              path = "/var/fluent-bit/state"
            }
          }
        }
        dynamic volume {
          for_each = (!local.fluent_bit_is_daemonset ? [1] : [])
          content {
            name = "varlog"
            host_path {
              path = "/var/log"
            }
          }
        }
        dynamic volume {
          for_each = (!local.fluent_bit_is_daemonset ? [1] : [])
          content {
            name = "varlibdockercontainers"
            host_path {
              path = "/var/lib/docker/containers"
            }
          }
        }
        dynamic volume {
          for_each = (!local.fluent_bit_is_daemonset ? [1] : [])
          content {
            name = "runlogjournal"
            host_path {
              path = "/run/log/journal"
            }
          }
        }
        dynamic volume {
          for_each = (!local.fluent_bit_is_daemonset ? [1] : [])
          content {
            name = "dmesg"
            host_path {
              path = "/var/log/dmesg"
            }
          }
        }
        dynamic volume {
          for_each = (!local.fluent_bit_is_daemonset ? [1] : [])
          content {
            name = "fluent-bit-config"
            config_map {
              name = local.fluent_bit_configmap
            }
          }
        }
      }
    }
  }
}