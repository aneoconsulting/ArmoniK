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
        node_selector = var.minioconfig.node_selector
        dynamic "toleration" {
          for_each = (var.minioconfig.node_selector != {} ? [
            for index in range(0, length(var.minioconfig.node_selector_keys)) : {
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

        container {
          name              = "minio"
          image             = "${var.minioconfig.image}:${var.minioconfig.tag}"
          image_pull_policy = "IfNotPresent"
                    command                    = ["/bin/bash"]
                    args                       = [
                        "-c",
                        "mkdir -p /data/${var.minioconfig.bucket_name} && minio server /data --console-address :9001"
                    ]
                    port {
                        container_port = var.minioconfig.port
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
        name        = "${kubernetes_deployment.minio.metadata.0.name}-${var.minioconfig.port}"
        #node_port   = 30900
        port        = var.minioconfig.port
        target_port = var.minioconfig.port
        protocol    = "TCP"
    }
    port {
        name        = "${kubernetes_deployment.minio.metadata.0.name}-9001"
        #node_port   = 30901
        port        = 9001
        target_port = 9001
        protocol    = "TCP"
    }
  }
}
