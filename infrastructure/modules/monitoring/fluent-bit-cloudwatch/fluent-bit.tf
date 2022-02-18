resource "kubernetes_daemonset" "fluent_bit" {
  metadata {
    name      = "fluent-bit-cloudwatch"
    namespace = var.namespace
    labels    = {
      "k8s-app"                       = "fluent-bit"
      "version"                       = "v1"
      "kubernetes.io/cluster-service" = "true"
    }
  }
  spec {
    selector {
      match_labels = {
        "k8s-app" = "fluent-bit"
      }
    }
    template {
      metadata {
        labels = {
          "k8s-app"                       = "fluent-bit"
          "version"                       = "v1"
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
          name              = "fluent-bit"
          image             = "${var.fluent_bit.image}:${var.fluent_bit.tag}"
          image_pull_policy = "Always"
          env {
            name  = "CLUSTER_NAME"
            value = var.cluster_info.cluster_name
          }
          env {
            name  = "HTTP_SERVER"
            value = (var.cluster_info.fluent_bit_http_port == 0 ? "Off" : "On")
          }
          env {
            name  = "HTTP_PORT"
            value = (var.cluster_info.fluent_bit_http_port == 0 ? "" : tostring(var.cluster_info.fluent_bit_http_port))
          }
          env {
            name  = "READ_FROM_HEAD"
            value = (var.cluster_info.fluent_bit_read_from_head ? "On" : "Off")
          }
          env {
            name  = "READ_FROM_TAIL"
            value = (var.cluster_info.fluent_bit_read_from_head ? "Off" : "On")
          }
          env {
            name  = "AWS_REGION"
            value = var.cluster_info.log_region
          }
          env {
            name = "HOST_NAME"
            value_from {
              field_ref {
                field_path = "spec.nodeName"
              }
            }
          }
          env {
            name  = "CI_VERSION"
            value = var.ci_version
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
            name       = "fluent-bit-config"
            mount_path = "/fluent-bit/etc/"
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
          name = "fluent-bit-config"
          config_map {
            name = kubernetes_config_map.fluent_bit_config.metadata.0.name
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
        termination_grace_period_seconds = 10
        service_account_name             = kubernetes_service_account.fluent_bit.metadata.0.name
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