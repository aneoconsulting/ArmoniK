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
        name        = "control-plane"
        namespace   = var.namespace
        labels      = {
          app     = "armonik"
          service = "control-plane"
        }
        annotations = local.control_plane_annotations
      }
      spec {
        node_selector  = local.control_plane_node_selector
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
            limits   = var.control_plane.limits
            requests = var.control_plane.requests
          }
          port {
            name           = "control-port"
            container_port = 1080
          }
          liveness_probe {
            tcp_socket {
              port = 1080
            }
            initial_delay_seconds = 15
            period_seconds        = 5
            timeout_seconds       = 1
            success_threshold     = 1
            failure_threshold     = 1
          }
          startup_probe {
            tcp_socket {
              port = 1080
            }
            initial_delay_seconds = 1
            period_seconds        = 3
            timeout_seconds       = 1
            success_threshold     = 1
            failure_threshold     = 20
            # the pod has (period_seconds x failure_threshold) seconds to finalize its startup
          }
          env_from {
            config_map_ref {
              name = kubernetes_config_map.core_config.metadata.0.name
            }
          }
          env_from {
            config_map_ref {
              name = kubernetes_config_map.log_config.metadata.0.name
            }
          }
          env_from {
            config_map_ref {
              name = kubernetes_config_map.control_plane_config.metadata.0.name
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
            for_each = local.certificates
            content {
              name       = volume_mount.value.name
              mount_path = volume_mount.value.mount_path
              read_only  = true
            }
          }
        }
        dynamic volume {
          for_each = local.certificates
          content {
            name = volume.value.name
            secret {
              secret_name = volume.value.secret_name
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
            image_pull_policy = "IfNotPresent"
            env_from {
              config_map_ref {
                name = local.fluent_bit_envvars_configmap
              }
            }
            # Please don't change below read-only permissions
            dynamic volume_mount {
              for_each = local.fluent_bit_volumes
              content {
                name       = volume_mount.value.name
                mount_path = volume_mount.value.mount_path
                read_only  = volume_mount.value.read_only
              }
            }
          }
        }
        dynamic volume {
          for_each = local.fluent_bit_volumes
          content {
            name = volume.value.name
            dynamic host_path {
              for_each = (volume.value.type == "host_path" ? [1] : [])
              content {
                path = volume.value.mount_path
              }
            }
            dynamic config_map {
              for_each = (volume.value.type == "config_map" ? [1] : [])
              content {
                name = local.fluent_bit_configmap
              }
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
    name        = kubernetes_deployment.control_plane.metadata.0.name
    namespace   = kubernetes_deployment.control_plane.metadata.0.namespace
    labels      = {
      app     = kubernetes_deployment.control_plane.metadata.0.labels.app
      service = kubernetes_deployment.control_plane.metadata.0.labels.service
    }
    annotations = var.control_plane.annotations
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
