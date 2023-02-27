# Control plane deployment
resource "kubernetes_deployment" "admin_gui" {
  count = var.admin_gui != null ? 1 : 0
  metadata {
    name      = "admin-gui"
    namespace = var.namespace
    labels = {
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
        labels = {
          app     = "armonik"
          service = "admin-gui"
        }
      }
      spec {
        dynamic "toleration" {
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
        dynamic "image_pull_secrets" {
          for_each = (var.admin_gui.image_pull_secrets != "" ? [1] : [])
          content {
            name = var.admin_gui.image_pull_secrets
          }
        }
        restart_policy = "Always" # Always, OnFailure, Never
        # App container
        container {
          name              = var.admin_gui.app.name
          image             = var.admin_gui.app.tag != "" ? "${var.admin_gui.app.image}:${var.admin_gui.app.tag}" : var.admin_gui.app.image
          image_pull_policy = var.admin_gui.image_pull_policy
          resources {
            limits   = var.admin_gui.app.limits
            requests = var.admin_gui.app.requests
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
          dynamic "env" {
            for_each = (data.kubernetes_secret.grafana.data.enabled != "" ? [1] : [])
            content {
              name  = "Grafana__Endpoint"
              value = data.kubernetes_secret.grafana.data.url
            }
          }
          dynamic "env" {
            for_each = (data.kubernetes_secret.seq.data.enabled ? [1] : [])
            content {
              name  = "Seq__Endpoint"
              value = data.kubernetes_secret.seq.data.web_url
            }
          }
          dynamic "env" {
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
          dynamic "volume_mount" {
            for_each = local.certificates
            content {
              name       = volume_mount.value.name
              mount_path = volume_mount.value.mount_path
              read_only  = true
            }
          }
        }
        # Secrets volumes
        dynamic "volume" {
          for_each = local.certificates
          content {
            name = volume.value.name
            secret {
              secret_name = volume.value.secret_name
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
  count = length(kubernetes_deployment.admin_gui)
  metadata {
    name      = kubernetes_deployment.admin_gui[0].metadata.0.name
    namespace = kubernetes_deployment.admin_gui[0].metadata.0.namespace
    labels = {
      app     = kubernetes_deployment.admin_gui[0].metadata.0.labels.app
      service = kubernetes_deployment.admin_gui[0].metadata.0.labels.service
    }
  }
  spec {
    type = var.admin_gui.service_type
    selector = {
      app     = kubernetes_deployment.admin_gui[0].metadata.0.labels.app
      service = kubernetes_deployment.admin_gui[0].metadata.0.labels.service
    }
    port {
      name        = kubernetes_deployment.admin_gui[0].spec.0.template.0.spec.0.container.1.port.0.name
      port        = var.admin_gui.app.port
      target_port = kubernetes_deployment.admin_gui[0].spec.0.template.0.spec.0.container.1.port.0.container_port
      protocol    = "TCP"
    }
  }
  timeouts {
    create = "2m"
  }
}
