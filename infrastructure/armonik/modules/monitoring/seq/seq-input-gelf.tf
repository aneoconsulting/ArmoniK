# seq deployment
resource "kubernetes_deployment" "seq_input_gelf" {
  depends_on = [
    kubernetes_deployment.seq
  ]
  metadata {
    name      = "seq-input-gelf"
    namespace = var.namespace
    labels    = {
      app     = "armonik"
      type    = "logs"
      service = "seq-input-gelf"
    }
  }
  spec {
    replicas = var.seq.replicas
    selector {
      match_labels = {
        app     = "armonik"
        type    = "logs"
        service = "seq-input-gelf"
      }
    }
    template {
      metadata {
        name      = "seq-input-gelf"
        namespace = var.namespace
        labels    = {
          app     = "armonik"
          type    = "logs"
          service = "seq-input-gelf"
        }
      }
      spec {
        container {
          name              = "seq-input-gelf"
          image             = "datalust/seq-input-gelf:latest"
          image_pull_policy = "IfNotPresent"
          env {
            name  = "SEQ_ADDRESS"
            value = "http://localhost:5341"
          }
          env {
            name  = "GELF_ENABLE_DIAGNOSTICS"
            value = "True"
          }
          port {
            container_port = 12201
            name           = "input-gulf"
            protocol       = "UDP"
          }
        }
      }
    }
  }
}

# Kubernetes Seq service
resource "kubernetes_service" "seq_input_gelf" {
  metadata {
    name      = kubernetes_deployment.seq_input_gelf.metadata.0.name
    namespace = kubernetes_deployment.seq_input_gelf.metadata.0.namespace
    labels    = {
      app     = kubernetes_deployment.seq_input_gelf.metadata.0.labels.app
      type    = kubernetes_deployment.seq_input_gelf.metadata.0.labels.type
      service = kubernetes_deployment.seq_input_gelf.metadata.0.labels.service
    }
  }
  spec {
    type                    = "LoadBalancer"
    selector                = {
      app     = kubernetes_deployment.seq_input_gelf.metadata.0.labels.app
      type    = kubernetes_deployment.seq_input_gelf.metadata.0.labels.type
      service = kubernetes_deployment.seq_input_gelf.metadata.0.labels.service
    }
    port {
      port        = 12201
      name        = kubernetes_deployment.seq_input_gelf.spec.0.template.0.spec.0.container.0.port.0.name
      target_port = kubernetes_deployment.seq_input_gelf.spec.0.template.0.spec.0.container.0.port.0.container_port
    }
  }
}
