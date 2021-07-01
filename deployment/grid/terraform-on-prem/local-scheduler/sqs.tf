resource "kubernetes_deployment" "htc_task_queue" {
  metadata {
    name      = "htc-task-queue"
    labels = {
      app = "local-scheduler"
      service = "htc-task-queue"
    }
  }
  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "local-scheduler"
        service = "htc-task-queue"
      }
    }
    
    template {
      metadata {
        labels = {
          app = "local-scheduler"
          service = "htc-task-queue"
        }
      }

      spec {
        container {
          image   = "localstack/localstack:latest"
          name    = "htc-task-queue"

          env {
            name = "SERVICES"
            value = "sqs"
          }
          env {
            name = "EDGE_PORT"
            value = var.htc_task_queue_port
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
            container_port = var.htc_task_queue_port
          }
        }
      }
    }
  }
}


resource "kubernetes_deployment" "htc_task_queue_dlq" {
  metadata {
    name      = "htc-task-queue-dlq"
    labels = {
      app = "local-scheduler"
      service = "htc-task-queue-dlq"
    }
  }
  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "local-scheduler"
        service = "htc-task-queue-dlq"
      }
    }
    
    template {
      metadata {
        labels = {
          app = "local-scheduler"
          service = "htc-task-queue-dlq"
        }
      }

      spec {
        container {
          image   = "localstack/localstack:latest"
          name    = "htc-task-queue-dlq"

          env {
            name = "SERVICES"
            value = "sqs"
          }
          env {
            name = "EDGE_PORT"
            value = var.htc_task_queue_dlq_port
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
            container_port = var.htc_task_queue_dlq_port
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "htc_task_queue" {
  metadata {
    name = "htc-task-queue"
  }

  spec {
    selector = {
      app     = kubernetes_deployment.htc_task_queue.metadata.0.labels.app
      service = kubernetes_deployment.htc_task_queue.metadata.0.labels.service
    }
    type = "LoadBalancer"
    port {
      protocol = "TCP"
      port = var.htc_task_queue_port
      name = "htc-task-queue"
    }
  }
}


resource "kubernetes_service" "htc_task_queue_dlq" {
  metadata {
    name = "htc-task-queue-dlq"
  }

  spec {
    selector = {
      app     = kubernetes_deployment.htc_task_queue_dlq.metadata.0.labels.app
      service = kubernetes_deployment.htc_task_queue_dlq.metadata.0.labels.service
    }
    type = "LoadBalancer"
    port {
      protocol = "TCP"
      port = var.htc_task_queue_dlq_port
      name = "htc-task-queue-dlq"
    }
  }
}
