resource "kubernetes_daemonset" "fluent_bit" {
  count = (var.fluent_bit.is_daemonset ? 1 : 0)
  metadata {
    name      = "fluent-bit"
    namespace = var.namespace
    labels    = {
      app                             = "armonik"
      type                            = "logs"
      service                         = "fluent-bit"
      version                         = "v1"
      "kubernetes.io/cluster-service" = "true"
    }
  }
  spec {
    selector {
      match_labels = {
        app                             = "armonik"
        type                            = "logs"
        service                         = "fluent-bit"
        version                         = "v1"
        "kubernetes.io/cluster-service" = "true"
      }
    }
    template {
      metadata {
        labels = {
          app                             = "armonik"
          type                            = "logs"
          service                         = "fluent-bit"
          version                         = "v1"
          "kubernetes.io/cluster-service" = "true"
        }
      }
      spec {
        dynamic toleration {
          for_each = (var.node_selector != {} ? [1] : [])
          content {
            key      = keys(var.node_selector)[0]
            operator = "Equal"
            value    = values(var.node_selector)[0]
            effect   = "NoSchedule"
          }
        }
        container {
          name              = local.fluent_bit_container_name
          image             = "${local.fluent_bit_image}:${local.fluent_bit_tag}"
          image_pull_policy = "Always"
          env {
            name = "HOSTNAME"
            value_from {
              field_ref {
                field_path = "spec.nodeName"
              }
            }
          }
          env_from {
            config_map_ref {
              name = kubernetes_config_map.fluent_bit_envvars_config.metadata.0.name
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
        volume {
          name = "fluentbitstate"
          host_path {
            path = "/var/fluent-bit/state"
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
          name = "runlogjournal"
          host_path {
            path = "/run/log/journal"
          }
        }
        volume {
          name = "dmesg"
          host_path {
            path = "/var/log/dmesg"
          }
        }
        volume {
          name = "fluent-bit-config"
          config_map {
            name = kubernetes_config_map.fluent_bit_config.metadata.0.name
          }
        }
        termination_grace_period_seconds = 10
        service_account_name             = kubernetes_service_account.fluent_bit.0.metadata.0.name
        toleration {
          key      = "node-role.kubernetes.io/master"
          operator = "Exists"
          effect   = "NoSchedule"
        }
        toleration {
          operator = "Exists"
          effect   = "NoExecute"
        }
        toleration {
          operator = "Exists"
          effect   = "NoSchedule"
        }
      }
    }
  }
}