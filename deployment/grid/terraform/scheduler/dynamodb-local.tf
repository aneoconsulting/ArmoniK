resource "kubernetes_stateful_set" "dynamodb" {
  metadata {
    name      = "dynamodb"
    labels = {
      app = "local-scheduler"
      service = "dynamodb"
    }
  }
  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "local-scheduler"
        service = "dynamodb"
      }
    }
    
    service_name = "dynamodb"

    template {
      metadata {
        labels = {
          app = "local-scheduler"
          service = "dynamodb"
        }
      }

      spec {
        container {
          image   = "localstack/localstack:latest"
          name    = "dynamodb"

          env {
            name = "SERVICES"
            value = "dynamodb,kinesis"
          }
          env {
            name = "EDGE_PORT"
            value = var.dynamodb_port
          }
          env {
            name = "DEFAULT_REGION"
            value = var.region
          }
          env {
            name = "DEBUG"
            value = "true"
          }
          env {
            name = "DATA_DIR"
            value = "/tmp/localstack/data" 
          }

          port {
            container_port = var.dynamodb_port
          }

          volume_mount {
            name       = "status-db"
            mount_path = "/tmp/localstack/data"
          }
        }

        volume {
          name = "status-db"
        }
      }
    }
  }
}

resource "kubernetes_service" "dynamodb" {
  metadata {
    name = "dynamodb"
  }

  spec {
    selector = {
      app     = kubernetes_stateful_set.dynamodb.metadata.0.labels.app
      service = kubernetes_stateful_set.dynamodb.metadata.0.labels.service
    }
    type = "LoadBalancer"
    port {
      protocol = "TCP"
      port = var.dynamodb_port
      name = "dynamodb"
    }
  }
}