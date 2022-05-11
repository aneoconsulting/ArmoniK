# Ingress deployment
resource "kubernetes_deployment" "ingress" {
  count = var.ingress != null ? 1 : 0

  metadata {
    name      = "ingress"
    namespace = var.namespace
    labels    = {
      app     = "armonik"
      service = "ingress"
    }
  }
  spec {
    replicas = var.ingress.replicas
    selector {
      match_labels = {
        app     = "armonik"
        service = "ingress"
      }
    }
    template {
      metadata {
        name      = "ingress"
        namespace = var.namespace
        labels    = {
          app     = "armonik"
          service = "ingress"
        }
      }
      spec {
        dynamic image_pull_secrets {
          for_each = (var.ingress.image_pull_secrets != "" ? [1] : [])
          content {
            name = var.ingress.image_pull_secrets
          }
        }
        restart_policy = "Always" # Always, OnFailure, Never
        # Control plane container
        container {
          name              = var.ingress.name
          image             = var.ingress.tag != "" ? "${var.ingress.image}:${var.ingress.tag}" : var.ingress.image
          image_pull_policy = var.ingress.image_pull_policy
          resources {
            limits   = {
              cpu    = var.ingress.limits.cpu
              memory = var.ingress.limits.memory
            }
            requests = {
              cpu    = var.ingress.requests.cpu
              memory = var.ingress.requests.memory
            }
          }
          dynamic port{
            for_each = local.ingress_ports
            content {
              name = "ingress-p-${port.key}"
              container_port = port.value
            }
          }
          env_from {
            config_map_ref {
              name = kubernetes_config_map.ingress.metadata.0.name
            }
          }
          volume_mount {
            name       = "ingress-secret-volume"
            mount_path = "/ingress"
            read_only  = true
          }
          volume_mount {
            name       = "ingress-client-secret-volume"
            mount_path = "/ingressclient"
            read_only  = true
          }
          volume_mount {
            name       = "ingress-nginx"
            mount_path = "/etc/nginx/conf.d"
            read_only  = true
          }
        }
        volume {
          name = "ingress-secret-volume"
          secret {
            secret_name = kubernetes_secret.ingress_certificate.metadata[0].name
            optional    = false
          }
        }
        volume {
          name = "ingress-client-secret-volume"
          secret {
            secret_name = kubernetes_secret.ingress_client_certificate.metadata[0].name
            optional = false
          }
        }
        volume {
          name = "ingress-nginx"
          config_map {
            name = kubernetes_config_map.ingress.metadata[0].name
            optional = false
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
                cpu    = "100m"
                memory = "50Mi"
              }
              requests = {
                cpu    = "1m"
                memory = "1Mi"
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
resource "kubernetes_service" "ingress" {
  count = var.ingress != null ? 1 : 0

  metadata {
    name      = kubernetes_deployment.ingress.0.metadata.0.name
    namespace = kubernetes_deployment.ingress.0.metadata.0.namespace
    labels    = {
      app     = kubernetes_deployment.ingress.0.metadata.0.labels.app
      service = kubernetes_deployment.ingress.0.metadata.0.labels.service
    }
  }
  spec {
    type     = var.ingress.service_type
    selector = {
      app     = kubernetes_deployment.ingress.0.metadata.0.labels.app
      service = kubernetes_deployment.ingress.0.metadata.0.labels.service
    }
    dynamic port {
      for_each = kubernetes_deployment.ingress.0.spec.0.template.0.spec.0.container.0.port
      content {
        name = port.value.name
        port = port.value.container_port
        target_port = port.value.container_port
        protocol = "TCP"
      }
    }
  }
}
