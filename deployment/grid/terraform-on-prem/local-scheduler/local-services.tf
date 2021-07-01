resource "kubernetes_deployment" "local_services" {
  metadata {
    name      = "local-services"
    labels = {
      app = "local-scheduler"
      service = "local-services"
    }
  }
  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "local-scheduler"
        service = "local-services"
      }
    }
    
    template {
      metadata {
        labels = {
          app = "local-scheduler"
          service = "local-services"
        }
      }

      spec {
        container {
          image   = "localstack/localstack:latest"
          name    = "local-services"

          env {
            name = "SERVICES"
            value = "iam,s3,cloudwatch,cloudwatchlogs,ec2"
          }
          env {
            name = "EDGE_PORT"
            value = var.local_services_port
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
            container_port = var.local_services_port
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "local_services" {
  metadata {
    name = "local-services"
  }

  spec {
    selector = {
      app     = kubernetes_deployment.local_services.metadata.0.labels.app
      service = kubernetes_deployment.local_services.metadata.0.labels.service
    }
    type = "LoadBalancer"
    port {
      protocol = "TCP"
      port = var.local_services_port
      name = "local-services"
    }
  }
}