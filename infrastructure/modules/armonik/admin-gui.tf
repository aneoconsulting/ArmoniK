# Control plane deployment
resource "kubernetes_deployment" "admin_gui" {
  metadata {
    name      = "admin-gui"
    namespace = var.namespace
    labels    = {
      app     = "armonik"
      service = "admin-gui"
    }
  }
  spec {
    replicas = var.admin_gui.replicas
    selector {
      match_labels = {
        app     = "armonik"
        service = "admin-gui"
      }
    }
    template {
      metadata {
        name      = "admin-gui"
        namespace = var.namespace
        labels    = {
          app     = "armonik"
          service = "admin-gui"
        }
      }
      spec {
        dynamic toleration {
          for_each = (local.admin_gui_node_selector != {} ? [
          for index in range(0, length(local.admin_gui_node_selector_keys)) : {
            key   = local.admin_gui_node_selector_keys[index]
            value = local.admin_gui_node_selector_values[index]
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
          for_each = (var.admin_gui.image_pull_secrets != "" ? [1] : [])
          content {
            name = var.admin_gui.image_pull_secrets
          }
        }
        restart_policy = "Always" # Always, OnFailure, Never
        # API container
        container {
          name              = var.admin_gui.api.name
          image             = var.admin_gui.api.tag != "" ? "${var.admin_gui.api.image}:${var.admin_gui.api.tag}" : var.admin_gui.api.image
          image_pull_policy = var.admin_gui.image_pull_policy
          resources {
            limits   = {
              cpu    = var.admin_gui.api.limits.cpu
              memory = var.admin_gui.api.limits.memory
            }
            requests = {
              cpu    = var.admin_gui.api.requests.cpu
              memory = var.admin_gui.api.requests.memory
            }
          }
          port {
            name           = "api-port"
            container_port = 3333
          }
          env_from {
            config_map_ref {
              name = kubernetes_config_map.core_config.metadata.0.name
            }
          }
          env {
            name  = "ControlPlane__Endpoint"
            value = local.control_plane_url
          }
          dynamic env {
            for_each = (local.grafana_url != "" ? [1] : [])
            content {
              name  = "Grafana__Endpoint"
              value = local.grafana_url
            }
          }
          dynamic env {
            for_each = (local.seq_web_url != "" ? [1] : [])
            content {
              name  = "Seq__Endpoint"
              value = local.seq_web_url
            }
          }
          dynamic env {
            for_each = local.credentials
            content {
              name = env.key
              value_from {
                secret_key_ref {
                  key      = env.value.key
                  name     = env.value.name
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
        # App container
        container {
          name              = var.admin_gui.app.name
          image             = var.admin_gui.app.tag != "" ? "${var.admin_gui.app.image}:${var.admin_gui.app.tag}" : var.admin_gui.app.image
          image_pull_policy = var.admin_gui.image_pull_policy
          resources {
            limits   = {
              cpu    = var.admin_gui.app.limits.cpu
              memory = var.admin_gui.app.limits.memory
            }
            requests = {
              cpu    = var.admin_gui.app.requests.cpu
              memory = var.admin_gui.app.requests.memory
            }
          }
          port {
            name           = "app-port"
            container_port = 1080
          }
          env_from {
            config_map_ref {
              name = kubernetes_config_map.core_config.metadata.0.name
            }
          }
          env {
            name  = "ControlPlane__Endpoint"
            value = local.control_plane_url
          }
          dynamic env {
            for_each = (local.grafana_url != "" ? [1] : [])
            content {
              name  = "Grafana__Endpoint"
              value = local.grafana_url
            }
          }
          dynamic env {
            for_each = (local.seq_web_url != "" ? [1] : [])
            content {
              name  = "Seq__Endpoint"
              value = local.seq_web_url
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
        # Secrets volumes
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

# Admin GUI service
resource "kubernetes_service" "admin_gui" {
  metadata {
    name      = kubernetes_deployment.admin_gui.metadata.0.name
    namespace = kubernetes_deployment.admin_gui.metadata.0.namespace
    labels    = {
      app     = kubernetes_deployment.admin_gui.metadata.0.labels.app
      service = kubernetes_deployment.admin_gui.metadata.0.labels.service
    }
  }
  spec {
    type     = var.admin_gui.service_type
    selector = {
      app     = kubernetes_deployment.admin_gui.metadata.0.labels.app
      service = kubernetes_deployment.admin_gui.metadata.0.labels.service
    }
    port {
      name        = kubernetes_deployment.admin_gui.spec.0.template.0.spec.0.container.0.port.0.name
      port        = var.admin_gui.api.port
      target_port = kubernetes_deployment.admin_gui.spec.0.template.0.spec.0.container.0.port.0.container_port
      protocol    = "TCP"
    }
    port {
      name        = kubernetes_deployment.admin_gui.spec.0.template.0.spec.0.container.1.port.0.name
      port        = var.admin_gui.app.port
      target_port = kubernetes_deployment.admin_gui.spec.0.template.0.spec.0.container.1.port.0.container_port
      protocol    = "TCP"
    }
  }

  timeouts {
    create = "2m"
  }
}
