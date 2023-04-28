# Kubernetes minio deployment
resource "kubernetes_deployment" "minio" {
  metadata {
    name      = var.minio.host
    namespace = var.namespace
    labels = {
      app     = "storage"
      type    = "object"
      service = var.minio.host
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app     = "storage"
        type    = "object"
        service = var.minio.host
      }
    }
    template {
      metadata {
        name = var.minio.host
        labels = {
          app     = "storage"
          type    = "object"
          service = var.minio.host
        }
      }
      spec {
        node_selector = var.minio.node_selector
        dynamic "toleration" {
          for_each = (var.minio.node_selector != {} ? [
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
          for_each = (var.minio.image_pull_secrets != "" ? [1] : [])
          content {
            name = var.minio.image_pull_secrets
          }
        }
        container {
          name              = "minio"
          image             = "${var.minio.image}:${var.minio.tag}"
          image_pull_policy = "IfNotPresent"
          command           = ["/bin/bash"]
          args = [
            "-c",
            "mkdir -p /data/${var.minio.bucket_name} && minio server /data --console-address :${local.console_port}"
          ]
          env {
            name  = "MINIO_ROOT_USER"
            value = random_string.minio_application_user.result
          }
          env {
            name  = "MINIO_ROOT_PASSWORD"
            value = random_password.minio_application_password.result
          }
          port {
            container_port = local.port
            protocol       = "TCP"
          }
          port {
            container_port = local.console_port
            protocol       = "TCP"
          }
        }
      }
    }
  }
}

# Kubernetes Minio service
resource "kubernetes_service" "minio" {
  metadata {
    name      = kubernetes_deployment.minio.metadata.0.name
    namespace = kubernetes_deployment.minio.metadata.0.namespace
    labels = {
      app     = kubernetes_deployment.minio.metadata.0.labels.app
      type    = kubernetes_deployment.minio.metadata.0.labels.type
      service = kubernetes_deployment.minio.metadata.0.labels.service
    }
  }
  spec {
    type = "ClusterIP"
    selector = {
      app     = kubernetes_deployment.minio.metadata.0.labels.app
      type    = kubernetes_deployment.minio.metadata.0.labels.type
      service = kubernetes_deployment.minio.metadata.0.labels.service
    }
    port {
      name        = "${kubernetes_deployment.minio.metadata.0.name}-${local.port}"
      port        = local.port
      target_port = local.port
      protocol    = "TCP"
    }
    port {
      name        = "${kubernetes_deployment.minio.metadata.0.name}-${local.console_port}"
      port        = local.console_port
      target_port = local.console_port
      protocol    = "TCP"
    }
  }
}
