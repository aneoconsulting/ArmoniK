# node-exporter daemonset
resource "kubernetes_daemonset" "node-exporter" {
  metadata {
    name      = "node-exporter"
    namespace = var.namespace
    labels    = {
      app     = "armonik"
      type    = "monitoring"
      service = "node-exporter"
    }
  }
  spec {
    selector {
      match_labels = {
        app     = "armonik"
        type    = "monitoring"
        service = "node-exporter"
      }
    }
    template {
      metadata {
        name        = "node-exporter"
        labels      = {
          app     = "armonik"
          type    = "monitoring"
          service = "node-exporter"
        }
        annotations = {
          "prometheus.io/scrape" = "true"
          "prometheus.io/port"   = "9100"
          "prometheus.io/input"  = "node-exporter"
        }
      }
      spec {
        node_selector = var.node_selector
        dynamic toleration {
          for_each = (var.node_selector != {} ? [
          for index in range(0, length(local.node_selector_keys)) : {
            key   = local.node_selector_keys[index]
            value = local.node_selector_values[index]
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
          for_each = (var.docker_image.image_pull_secrets != "" ? [1] : [])
          content {
            name = var.docker_image.image_pull_secrets
          }
        }
        container {
          name              = "node-exporter"
          image             = "${var.docker_image.image}:${var.docker_image.tag}"
          image_pull_policy = "IfNotPresent"
          args              = [
            "--path.procfs",
            "/host/proc",
            "--path.sysfs",
            "/host/sys",
            "--collector.filesystem.ignored-mount-points",
            "^/(sys|proc|dev|host|etc)($|/)"
          ]
          port {
            name           = "node-exporter"
            container_port = 9100
            protocol       = "TCP"
          }
          volume_mount {
            name       = "dev"
            mount_path = "/host/dev"
          }
          volume_mount {
            name       = "proc"
            mount_path = "/host/proc"
          }
          volume_mount {
            name       = "sys"
            mount_path = "/host/sys"
          }
          volume_mount {
            name       = "rootfs"
            mount_path = "/rootfs"
          }
        }
        volume {
          name = "proc"
          host_path {
            path = "/proc"
          }
        }
        volume {
          name = "dev"
          host_path {
            path = "/dev"
          }
        }
        volume {
          name = "sys"
          host_path {
            path = "/sys"
          }
        }
        volume {
          name = "rootfs"
          host_path {
            path = "/"
          }
        }
      }
    }
  }
}