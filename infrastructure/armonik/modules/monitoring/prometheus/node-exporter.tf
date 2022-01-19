# nodeexporter daemonset
resource "kubernetes_daemonset" "nodeexporter" {
  metadata {
    name      = "nodeexporter"
    namespace = var.namespace
    labels    = {
      app     = "armonik"
      type    = "monitoring"
      service = "nodeexporter"
    }
  }
  spec {
    selector {
      match_labels = {
        app     = "armonik"
        type    = "monitoring"
        service = "nodeexporter"
      }
    }
    template {
      metadata {
        name      = "nodeexporter"
        labels    = {
          app     = "armonik"
          type    = "monitoring"
          service = "nodeexporter"
        }
        annotations = {
          "prometheus.io/scrape" = "true"
          "prometheus.io/port" = "9100"
          "prometheus.io/input" = "nodeexporter"
        }
      }
      spec {
        # security_context {
        #   privilegied = true
        # }
        container {
          name              = "nodeexporter"
          image             = "prom/node-exporter:latest"
          image_pull_policy = "IfNotPresent"

          args = [
            "--path.procfs",
            "/host/proc",
            "--path.sysfs",
            "/host/sys",
            "--collector.filesystem.ignored-mount-points",
            "^/(sys|proc|dev|host|etc)($|/)"
          ]

          port {
            name           = "nodeexporter"
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