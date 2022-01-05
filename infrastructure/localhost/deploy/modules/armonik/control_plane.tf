# ArmoniK control plane

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
    replicas = var.armonik.control_plane.replicas
    selector {
      match_labels = {
        app     = "armonik"
        service = "control-plane"
      }
    }
    template {
      metadata {
        name      = "control-plane"
        namespace = var.namespace
        labels    = {
          app     = "armonik"
          service = "control-plane"
        }
      }
      spec {
        container {
          name              = "control-plane"
          image             = var.armonik.control_plane.tag != "" ? "${var.armonik.control_plane.image}:${var.armonik.control_plane.tag}" : var.armonik.control_plane.image
          image_pull_policy = var.armonik.control_plane.image_pull_policy
          port {
            name           = "control-port"
            container_port = 80
          }
          volume_mount {
            name       = "control-plane-configmap"
            mount_path = "/app/appsettings.json"
            sub_path   = "appsettings.json"
          }
          volume_mount {
            name       = "shared-volume"
            mount_path = var.armonik.storage_services.shared_storage.target_path
          }
          dynamic volume_mount {
            for_each = (var.armonik.secrets.activemq_secret == "" ? [] : ["amqp"])
            content {
              name       = "queue-storage-secret-volume"
              mount_path = "/amqp"
              read_only  = true
            }
          }
        }
        volume {
          name = "control-plane-configmap"
          config_map {
            name     = kubernetes_config_map.control_plane_config.metadata.0.name
            optional = false
          }
        }
        volume {
          name = "shared-volume"
          persistent_volume_claim {
            claim_name = var.armonik.storage_services.shared_storage.claim_name
          }
        }
        dynamic volume {
          for_each = (var.armonik.secrets.activemq_secret == "" ? [] : ["amqp"])
          content {
            name = "queue-storage-secret-volume"
            secret {
              secret_name = var.armonik.secrets.activemq_secret
              optional    = false
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
    name      = kubernetes_deployment.control_plane.metadata.0.name
    namespace = kubernetes_deployment.control_plane.metadata.0.namespace
    labels    = {
      app     = kubernetes_deployment.control_plane.metadata.0.labels.app
      service = kubernetes_deployment.control_plane.metadata.0.labels.service
    }
  }
  spec {
    type     = "LoadBalancer"
    selector = {
      app     = kubernetes_deployment.control_plane.metadata.0.labels.app
      service = kubernetes_deployment.control_plane.metadata.0.labels.service
    }
    port {
      name        = kubernetes_deployment.control_plane.spec.0.template.0.spec.0.container.0.port.0.name
      port        = var.armonik.control_plane.port
      target_port = kubernetes_deployment.control_plane.spec.0.template.0.spec.0.container.0.port.0.container_port
      protocol    = "TCP"
    }
  }
}