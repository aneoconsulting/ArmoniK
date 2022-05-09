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
        dynamic toleration {
          for_each = (local.control_plane_node_selector != {} ? [
          for index in range(0, length(local.control_plane_node_selector_keys)) : {
            key   = local.control_plane_node_selector_keys[index]
            value = local.control_plane_node_selector_values[index]
          }
          ] : [])
          content {
            key      = toleration.value.key
            operator = "Equal"
            value    = toleration.value.value
            effect   = "NoSchedule"
          }
        }
        dynamic image_pull_secrets {
          for_each = (var.control_plane.image_pull_secrets != "" ? [1] : [])
          content {
            name = var.control_plane.image_pull_secrets
          }
        }
        restart_policy = "Always" # Always, OnFailure, Never
        # Control plane container
        container {
          name              = var.control_plane.name
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
    type     = var.control_plane.service_type
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