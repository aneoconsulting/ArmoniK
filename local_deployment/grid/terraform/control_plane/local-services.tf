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
          image   = "localstack/localstack-full:0.12.6"
          name    = "local-services"

          env {
            name = "SERVICES"
            value = "iam,cloudwatch,logs,ec2,events,lambda,sqs"
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
          env {
            name = "USE_SSL"
            value = "true"
          }
          env {
            name = "DATA_DIR"
            value = "/tmp/localstack/data"
          }

          port {
            container_port = var.local_services_port
          }

          volume_mount {
            name = "localstack-data"
            mount_path = "/tmp/localstack"
          }
        }

        volume {
          name = "localstack-data"
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