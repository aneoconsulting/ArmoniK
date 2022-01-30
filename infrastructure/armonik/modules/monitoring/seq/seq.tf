# seq deployment
resource "kubernetes_deployment" "seq" {
  metadata {
    name      = "seq"
    namespace = var.namespace
    labels    = {
      app     = "armonik"
      type    = "logs"
      service = "seq"
    }
  }
  spec {
    replicas = var.seq.replicas
    selector {
      match_labels = {
        app     = "armonik"
        type    = "logs"
        service = "seq"
      }
    }
    template {
      metadata {
        name      = "seq"
        namespace = var.namespace
        labels    = {
          app     = "armonik"
          type    = "logs"
          service = "seq"
        }
      }
      spec {
        container {
          name              = "seq"
          image             = "${var.docker_image.image}:${var.docker_image.tag}"
          image_pull_policy = "IfNotPresent"
          env {
            name  = "ACCEPT_EULA"
            value = "Y"
          }
          env {
            name  = "SEQ_FIRSTRUN_ADMINPASSWORDHASH"
            value = "FMB0CwtRt8CwkiSDebSmdJszUzK9B52DV19CKdpFyGtrGRkBrQ=="
          }
          dynamic port {
            for_each = var.seq.port
            content {
              name           = port.value.name
              container_port = port.value.target_port
              protocol       = port.value.protocol
            }
          }
        }
      }
    }
  }
}

# Kubernetes Seq service
resource "kubernetes_service" "seq" {
  metadata {
    name      = kubernetes_deployment.seq.metadata.0.name
    namespace = kubernetes_deployment.seq.metadata.0.namespace
    labels    = {
      app     = kubernetes_deployment.seq.metadata.0.labels.app
      type    = kubernetes_deployment.seq.metadata.0.labels.type
      service = kubernetes_deployment.seq.metadata.0.labels.service
    }
  }
  spec {
    type     = "LoadBalancer"
    selector = {
      app     = kubernetes_deployment.seq.metadata.0.labels.app
      type    = kubernetes_deployment.seq.metadata.0.labels.type
      service = kubernetes_deployment.seq.metadata.0.labels.service
    }
    dynamic port {
      for_each = var.seq.port
      content {
        name        = port.value.name
        port        = port.value.port
        target_port = port.value.target_port
        protocol    = port.value.protocol
      }
    }
  }
}
