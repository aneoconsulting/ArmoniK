# Kubernetes minio deployment
resource "kubernetes_deployment" "minio" {
  metadata {
    name      = "minio"
    namespace = var.namespace
    labels = {
      app     = "storage"
      type    = "object"
      service = "minio"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app     = "storage"
        type    = "object"
        service = "minio"
      }
    }
    template {
      metadata {
        name = "minio"
        labels = {
          app     = "storage"
          type    = "object"
          service = "minio"
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
            "mkdir -p /data/${var.minio.bucket_name} && minio server /data --console-address :9001"
          ]
          port {
            container_port = local.port
            protocol       = "TCP"
          }
          port {
            container_port = 9001
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
      name        = "${kubernetes_deployment.minio.metadata.0.name}-9001"
      port        = 9001
      target_port = 9001
      protocol    = "TCP"
    }
  }
}
