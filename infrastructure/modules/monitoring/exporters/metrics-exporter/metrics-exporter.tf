# Metrics exporter deployment
resource "kubernetes_deployment" "metrics_exporter" {
  metadata {
    name      = "metrics-exporter"
    namespace = var.namespace
    labels = {
      app     = "armonik"
      type    = "monitoring"
      service = "metrics-exporter"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app     = "armonik"
        type    = "monitoring"
        service = "metrics-exporter"
      }
    }
    template {
      metadata {
        name      = "metrics-exporter"
        namespace = var.namespace
        labels = {
          app     = "armonik"
          type    = "monitoring"
          service = "metrics-exporter"
        }
      }
      spec {
        node_selector = var.node_selector
        dynamic "toleration" {
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
        dynamic "image_pull_secrets" {
          for_each = (var.docker_image.image_pull_secrets != "" ? [1] : [])
          content {
            name = var.docker_image.image_pull_secrets
          }
        }
        container {
          name              = "metrics-exporter"
          image             = var.docker_image.tag != "" ? "${var.docker_image.image}:${var.docker_image.tag}" : var.docker_image.image
          image_pull_policy = "IfNotPresent"
          port {
            name           = "metrics"
            container_port = 1080
          }
          env_from {
            config_map_ref {
              name = kubernetes_config_map.metrics_exporter_config.metadata.0.name
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

# Control plane service
resource "kubernetes_service" "metrics_exporter" {
  metadata {
    name      = kubernetes_deployment.metrics_exporter.metadata.0.name
    namespace = kubernetes_deployment.metrics_exporter.metadata.0.namespace
    labels = {
      app     = kubernetes_deployment.metrics_exporter.metadata.0.labels.app
      service = kubernetes_deployment.metrics_exporter.metadata.0.labels.service
    }
  }
  spec {
    type = var.service_type
    selector = {
      app     = kubernetes_deployment.metrics_exporter.metadata.0.labels.app
      service = kubernetes_deployment.metrics_exporter.metadata.0.labels.service
    }
    port {
      name        = kubernetes_deployment.metrics_exporter.spec.0.template.0.spec.0.container.0.port.0.name
      port        = 9419
      target_port = 1080
      protocol    = "TCP"
    }
  }
}