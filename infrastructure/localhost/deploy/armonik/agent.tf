# ArmoniK agent

# Agent deployment
resource "kubernetes_deployment" "agent" {
  metadata {
    name      = "agent"
    namespace = var.namespace
    labels    = {
      app     = "armonik"
      service = "agent"
    }
  }
  spec {
    replicas = var.armonik.agent.replicas
    selector {
      match_labels = {
        app     = "armonik"
        service = "agent"
      }
    }
    template {
      metadata {
        name      = "agent"
        namespace = var.namespace
        labels    = {
          app     = "armonik"
          service = "agent"
        }
      }
      spec {
        share_process_namespace = true
        security_context {}
        container {
          name              = "polling-agent"
          image             = var.armonik.agent.polling_agent.image
          image_pull_policy = var.armonik.agent.polling_agent.image_pull_policy
          security_context {
            capabilities {
              drop = ["SYS_PTRACE"]
            }
          }
          resources {
            limits   = {
              cpu    = var.armonik.agent.polling_agent.limits.cpu
              memory = var.armonik.agent.polling_agent.limits.memory
            }
            requests = {
              cpu    = var.armonik.agent.polling_agent.requests.cpu
              memory = var.armonik.agent.polling_agent.requests.memory
            }
          }
          volume_mount {
            name       = "polling-agent-configmap"
            mount_path = "/app/appsettings.json"
            sub_path   = "appsettings.json"
          }
          volume_mount {
            name       = "shared-volume"
            mount_path = "/app/data"
          }
          volume_mount {
            name       = "object-storage-secret-volume"
            mount_path = "/certificates"
            read_only  = true
          }
        }
        container {
          name              = "compute"
          image             = var.armonik.agent.compute.image
          image_pull_policy = var.armonik.agent.compute.image_pull_policy
          port {
            container_port = var.armonik.agent.compute.port
          }
          resources {
            limits   = {
              cpu    = var.armonik.agent.compute.limits.cpu
              memory = var.armonik.agent.compute.limits.memory
            }
            requests = {
              cpu    = var.armonik.agent.compute.requests.cpu
              memory = var.armonik.agent.compute.requests.memory
            }
          }
          volume_mount {
            name       = "compute-configmap"
            mount_path = "/app/appsettings.json"
            sub_path   = "appsettings.json"
          }
          volume_mount {
            name       = "shared-volume"
            mount_path = "/app/data"
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
          name = "compute-configmap"
          config_map {
            name     = kubernetes_config_map.compute_config.metadata.0.name
            optional = false
          }
        }
        volume {
          name = "shared-volume"
          persistent_volume_claim {
            claim_name = var.armonik.storage_services.shared_storage
          }
        }
        volume {
          name = "object-storage-secret-volume"
          secret {
            secret_name = var.armonik.agent.polling_agent.object_storage_secret
            optional    = false
          }
        }
      }
    }
  }
}