# ArmoniK agent

# Agent deployment
resource "kubernetes_deployment" "compute_plane" {
  count = (var.max_priority == 0 ? 1 : var.max_priority)
  metadata {
    name      = "compute-plane-${count.index}"
    namespace = var.namespace
    labels    = {
      app     = "armonik"
      service = "compute-plane"
    }
  }
  spec {
    replicas = var.armonik.compute_plane.replicas
    selector {
      match_labels = {
        app     = "armonik"
        service = "compute-plane"
      }
    }
    template {
      metadata {
        name      = "compute-plane-${count.index}"
        namespace = var.namespace
        labels    = {
          app     = "armonik"
          service = "compute-plane"
        }
      }
      spec {
        share_process_namespace = true
        security_context {}
        container {
          name              = "polling-agent"
          image             = var.armonik.compute_plane.polling_agent.tag != "" ? "${var.armonik.compute_plane.polling_agent.image}:${var.armonik.compute_plane.polling_agent.tag}" : var.armonik.compute_plane.polling_agent.image
          image_pull_policy = var.armonik.compute_plane.polling_agent.image_pull_policy
          security_context {
            capabilities {
              drop = ["SYS_PTRACE"]
            }
          }
          resources {
            limits   = {
              cpu    = var.armonik.compute_plane.polling_agent.limits.cpu
              memory = var.armonik.compute_plane.polling_agent.limits.memory
            }
            requests = {
              cpu    = var.armonik.compute_plane.polling_agent.requests.cpu
              memory = var.armonik.compute_plane.polling_agent.requests.memory
            }
          }
          volume_mount {
            name       = "polling-agent-configmap"
            mount_path = "/app/appsettings.json"
            sub_path   = "appsettings.json"
          }
          volume_mount {
            name       = "shared-volume"
            mount_path = var.armonik.storage_services.shared_storage.target_path
          }
          volume_mount {
            name       = "cache-volume"
            mount_path = "/cache"
          }
        }
        # Containers of compute
        dynamic container {
          iterator = compute
          for_each = var.armonik.compute_plane.compute
          content {
            name              = "${compute.value.name}-${compute.key}"
            image             = compute.value.tag != "" ? "${compute.value.image}:${compute.value.tag}" : compute.value.image
            image_pull_policy = compute.value.image_pull_policy
            port {
              container_port = compute.value.port
            }
            resources {
              limits   = {
                cpu    = compute.value.limits.cpu
                memory = compute.value.limits.memory
              }
              requests = {
                cpu    = compute.value.requests.cpu
                memory = compute.value.requests.memory
              }
            }
            volume_mount {
              name       = "compute-configmap"
              mount_path = "/app/appsettings.json"
              sub_path   = "appsettings.json"
            }
            volume_mount {
              name       = "shared-volume"
              mount_path = var.armonik.storage_services.shared_storage.target_path
            }
            volume_mount {
              name       = "cache-volume"
              mount_path = "/cache"
            }
            volume_mount {
              name       = "compute-secret-volume"
              mount_path = "/certificates"
              read_only  = true
            }
          }
        }
        volume {
          name = "polling-agent-configmap"
          config_map {
            name     = kubernetes_config_map.polling_agent_config.metadata.0.name
            optional = false
          }
        }
        volume {
          name = "shared-volume"
          persistent_volume_claim {
            claim_name = var.armonik.storage_services.shared_storage.claim_name
          }
        }
        volume {
          name = "compute-configmap"
          config_map {
            name     = kubernetes_config_map.compute_config.metadata.0.name
            optional = false
          }
        }
        volume {
          name = "cache-volume"
          empty_dir {}
        }
        volume {
          name = "compute-secret-volume"
          secret {
            secret_name = var.armonik.secrets.redis_secret
            optional    = false
          }
        }
      }
    }
  }
}