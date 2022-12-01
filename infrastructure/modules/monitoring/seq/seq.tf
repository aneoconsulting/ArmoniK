# seq deployment
resource "kubernetes_deployment" "seq" {
  metadata {
    name      = "seq"
    namespace = var.namespace
    labels = {
      app     = "armonik"
      type    = "logs"
      service = "seq"
    }
  }
  spec {
    replicas = 1
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
        labels = {
          app     = "armonik"
          type    = "logs"
          service = "seq"
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
          name              = "seq"
          image             = "${var.docker_image.image}:${var.docker_image.tag}"
          image_pull_policy = "IfNotPresent"
          env {
            name  = "ACCEPT_EULA"
            value = "Y"
          }
          env {
            name  = "SEQ_CACHE_SYSTEMRAMTARGET"
            value = "0.5"
          }
          dynamic "env" {
            for_each = var.authentication ? [true] : []
            content {
              name  = "SEQ_FIRSTRUN_ADMINPASSWORDHASH"
              value = "FMB0CwtRt8CwkiSDebSmdJszUzK9B52DV19CKdpFyGtrGRkBrQ=="
            }
          }
          port {
            name           = "ingestion"
            container_port = 5341
            protocol       = "TCP"
          }
          port {
            name           = "web"
            container_port = 80
            protocol       = "TCP"
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
    labels = {
      app     = kubernetes_deployment.seq.metadata.0.labels.app
      type    = kubernetes_deployment.seq.metadata.0.labels.type
      service = kubernetes_deployment.seq.metadata.0.labels.service
    }
  }
  spec {
    type = "ClusterIP"
    selector = {
      app     = kubernetes_deployment.seq.metadata.0.labels.app
      type    = kubernetes_deployment.seq.metadata.0.labels.type
      service = kubernetes_deployment.seq.metadata.0.labels.service
    }
    port {
      name        = "ingestion"
      port        = 5341
      target_port = 5341
      protocol    = "TCP"
    }
  }
}

# Kubernetes Seq web console service
resource "kubernetes_service" "seq_web_console" {
  metadata {
    name      = "seq-web-console"
    namespace = kubernetes_deployment.seq.metadata.0.namespace
    labels = {
      app     = kubernetes_deployment.seq.metadata.0.labels.app
      type    = kubernetes_deployment.seq.metadata.0.labels.type
      service = kubernetes_deployment.seq.metadata.0.labels.service
    }
  }
  spec {
    type = var.service_type
    selector = {
      app     = kubernetes_deployment.seq.metadata.0.labels.app
      type    = kubernetes_deployment.seq.metadata.0.labels.type
      service = kubernetes_deployment.seq.metadata.0.labels.service
    }
    port {
      name        = "web"
      port        = var.port
      target_port = 80
      protocol    = "TCP"
    }
  }
}
