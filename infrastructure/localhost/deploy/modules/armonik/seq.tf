# ArmoniK seq

# seq deployment
resource "kubernetes_deployment" "seq" {
  metadata {
    name      = "seq"
    namespace = var.namespace
    labels    = {
      app     = "armonik"
      service = "seq"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app     = "armonik"
        service = "seq"
      }
    }
    template {
      metadata {
        name      = "seq"
        namespace = var.namespace
        labels    = {
          app     = "armonik"
          service = "seq"
        }
      }
      spec {
        container {
          name              = "seq"
          image             = "datalust/seq"
          image_pull_policy = "IfNotPresent"
          env {
            name = "ACCEPT_EULA"
            value = "Y"
          }
          env {
            name = "SEQ_FIRSTRUN_ADMINPASSWORDHASH"
            value = "FMB0CwtRt8CwkiSDebSmdJszUzK9B52DV19CKdpFyGtrGRkBrQ=="
          }
          port {
            name           = "ingestion"
            container_port = 5341
          }
          port {
            name           = "web"
            container_port = 80
          }
        }
      }
    }
  }
}

# seq service
resource "kubernetes_service" "seq_ingestion" {
  metadata {
    name      = "seqingestion"
    namespace = kubernetes_deployment.seq.metadata.0.namespace
    labels    = {
      app     = kubernetes_deployment.seq.metadata.0.labels.app
      service = kubernetes_deployment.seq.metadata.0.labels.service
    }
  }
  spec {
    type     = "ClusterIP"
    selector = {
      app     = kubernetes_deployment.seq.metadata.0.labels.app
      service = kubernetes_deployment.seq.metadata.0.labels.service
    }
    port {
      name        = kubernetes_deployment.seq.spec.0.template.0.spec.0.container.0.port.0.name
      port        = 5341
      target_port = kubernetes_deployment.seq.spec.0.template.0.spec.0.container.0.port.0.container_port
      protocol    = "TCP"
    }
  }
}

resource "kubernetes_service" "seq_web" {
  metadata {
    name      = "seqweb"
    namespace = kubernetes_deployment.seq.metadata.0.namespace
    labels    = {
      app     = kubernetes_deployment.seq.metadata.0.labels.app
      service = kubernetes_deployment.seq.metadata.0.labels.service
    }
  }
  spec {
    type     = "ClusterIP"
    selector = {
      app     = kubernetes_deployment.seq.metadata.0.labels.app
      service = kubernetes_deployment.seq.metadata.0.labels.service
    }
    port {
      name        = kubernetes_deployment.seq.spec.0.template.0.spec.0.container.0.port.1.name
      port        = 8080
      target_port = kubernetes_deployment.seq.spec.0.template.0.spec.0.container.0.port.1.container_port
      protocol    = "TCP"
    }
  }
}