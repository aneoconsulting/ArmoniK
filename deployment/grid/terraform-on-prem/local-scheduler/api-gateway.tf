resource "kubernetes_deployment" "api_gateway" {
  metadata {
    name      = "api-gateway"
    labels = {
      app = "local-scheduler"
      service = "api-gateway"
    }
  }
  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "local-scheduler"
        service = "api-gateway"
      }
    }
    
    template {
      metadata {
        labels = {
          app = "local-scheduler"
          service = "api-gateway"
        }
      }

      spec {
        container {
          image   = "localstack/localstack:latest"
          name    = "api-gateway"

          env {
            name = "SERVICES"
            value = "sqs"
          }
          env {
            name = "EDGE_PORT"
            value = var.api_gateway_port
          }
          env {
            name = "DEFAULT_REGION"
            value = var.region
          }
          env {
            name = "DEBUG"
            value = "true"
          }

          port {
            container_port = var.api_gateway_port
          }
        }
      }
    }
  }
}


resource "kubernetes_service" "api_gateway" {
  metadata {
    name = "api-gateway"
  }

  spec {
    selector = {
      app     = kubernetes_deployment.api_gateway.metadata.0.labels.app
      service = kubernetes_deployment.api_gateway.metadata.0.labels.service
    }
    type = "LoadBalancer"
    port {
      protocol = "TCP"
      port = var.api_gateway_port
      name = "api-gateway"
    }
  }
}