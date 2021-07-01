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