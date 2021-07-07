resource "kubernetes_deployment" "cancel_tasks" {
  metadata {
    name      = "cancel-tasks"
    labels = {
      app = "local-scheduler"
      service = "cancel-tasks"
    }
  }
  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "local-scheduler"
        service = "cancel-tasks"
      }
    }
    
    template {
      metadata {
        labels = {
          app = "local-scheduler"
          service = "cancel-tasks"
        }
      }

      spec {
        container {
          image   = "localstack/localstack:latest"
          name    = "cancel-tasks"

          env {
            name = "SERVICES"
            value = "lambda"
          }
          env {
            name = "EDGE_PORT"
            value = var.cancel_tasks_port
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
            container_port = var.cancel_tasks_port
          }
        }
      }
    }
  }
}

resource "kubernetes_deployment" "submit_task" {
  metadata {
    name      = "submit-task"
    labels = {
      app = "local-scheduler"
      service = "submit-task"
    }
  }
  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "local-scheduler"
        service = "submit-task"
      }
    }
    
    template {
      metadata {
        labels = {
          app = "local-scheduler"
          service = "submit-task"
        }
      }

      spec {
        container {
          image   = "localstack/localstack:latest"
          name    = "submit-task"

          env {
            name = "SERVICES"
            value = "lambda"
          }
          env {
            name = "EDGE_PORT"
            value = var.submit_task_port
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
            container_port = var.submit_task_port
          }
        }
      }
    }
  }
}

resource "kubernetes_deployment" "get_results" {
  metadata {
    name      = "get-results"
    labels = {
      app = "local-scheduler"
      service = "get-results"
    }
  }
  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "local-scheduler"
        service = "get-results"
      }
    }
    
    template {
      metadata {
        labels = {
          app = "local-scheduler"
          service = "get-results"
        }
      }

      spec {
        container {
          image   = "localstack/localstack:latest"
          name    = "get-results"

          env {
            name = "SERVICES"
            value = "lambda"
          }
          env {
            name = "EDGE_PORT"
            value = var.get_results_port
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
            container_port = var.get_results_port
          }
        }
      }
    }
  }
}

resource "kubernetes_deployment" "ttl_checker" {
  metadata {
    name      = "ttl-checker"
    labels = {
      app = "local-scheduler"
      service = "ttl-checker"
    }
  }
  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "local-scheduler"
        service = "ttl-checker"
      }
    }
    
    template {
      metadata {
        labels = {
          app = "local-scheduler"
          service = "ttl-checker"
        }
      }

      spec {
        container {
          image   = "localstack/localstack:latest"
          name    = "ttl-checker"

          env {
            name = "SERVICES"
            value = "lambda"
          }
          env {
            name = "EDGE_PORT"
            value = var.ttl_checker_port
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
            container_port = var.ttl_checker_port
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "cancel_tasks" {
  metadata {
    name = "cancel-tasks"
  }

  spec {
    selector = {
      app     = kubernetes_deployment.cancel_tasks.metadata.0.labels.app
      service = kubernetes_deployment.cancel_tasks.metadata.0.labels.service
    }
    type = "LoadBalancer"
    port {
      protocol = "TCP"
      port = var.cancel_tasks_port
      name = "cancel-tasks"
    }
  }
}

resource "kubernetes_service" "submit_task" {
  metadata {
    name = "submit-task"
  }

  spec {
    selector = {
      app     = kubernetes_deployment.submit_task.metadata.0.labels.app
      service = kubernetes_deployment.submit_task.metadata.0.labels.service
    }
    type = "LoadBalancer"
    port {
      protocol = "TCP"
      port = var.submit_task_port
      name = "submit-task"
    }
  }
}

resource "kubernetes_service" "get_results" {
  metadata {
    name = "get-results"
  }

  spec {
    selector = {
      app     = kubernetes_deployment.get_results.metadata.0.labels.app
      service = kubernetes_deployment.get_results.metadata.0.labels.service
    }
    type = "LoadBalancer"
    port {
      protocol = "TCP"
      port = var.get_results_port
      name = "get-results"
    }
  }
}

resource "kubernetes_service" "ttl_checker" {
  metadata {
    name = "ttl-checker"
  }

  spec {
    selector = {
      app     = kubernetes_deployment.ttl_checker.metadata.0.labels.app
      service = kubernetes_deployment.ttl_checker.metadata.0.labels.service
    }
    type = "LoadBalancer"
    port {
      protocol = "TCP"
      port = var.ttl_checker_port
      name = "ttl-checker"
    }
  }
}