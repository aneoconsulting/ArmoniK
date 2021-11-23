resource "kubernetes_config_map" "lambda_local" {
  metadata {
    name = "lambda-local"
  }

  data = {
    TASKS_STATUS_TABLE_NAME = var.ddb_status_table,
    TASKS_STATUS_TABLE_SERVICE = var.tasks_status_table_service,
    TASKS_STATUS_TABLE_CONFIG = var.tasks_status_table_config,
    TASKS_QUEUE_NAME = var.tasks_queue_name,
    TASKS_QUEUE_DLQ_NAME = var.dlq_name,
    METRICS_ARE_ENABLED = var.metrics_are_enabled,
    METRICS_SUBMIT_TASKS_LAMBDA_CONNECTION_STRING = var.metrics_submit_tasks_lambda_connection_string,
    TASK_INPUT_PASSED_VIA_EXTERNAL_STORAGE = var.task_input_passed_via_external_storage,
    GRID_STORAGE_SERVICE = var.grid_storage_service,
    GRID_QUEUE_SERVICE = var.grid_queue_service,
    GRID_QUEUE_CONFIG = var.grid_queue_config,
    REDIS_URL = local.redis_pod_ip,
    REDIS_PORT = var.redis_port,
    METRICS_GRAFANA_PRIVATE_IP = var.nlb_influxdb,
    QUEUE_ENDPOINT_URL = "${local.queue_pod_ip}:${var.queue_port}",
    DB_ENDPOINT_URL = "mongodb://${local.mongodb_pod_ip}:${var.mongodb_port}",
    REDIS_USE_SSL = var.redis_with_ssl,
    REDIS_CERTFILE = var.redis_cert_file,
    REDIS_KEYFILE = var.redis_key_file,
    REDIS_CA_CERT = var.redis_ca_cert,
    AWS_LAMBDA_FUNCTION_TIMEOUT = var.lambda_timeout,
    API_GATEWAY_SERVICE = var.api_gateway_service,
    METRICS_GET_RESULTS_LAMBDA_CONNECTION_STRING = var.metrics_get_results_lambda_connection_string,
    METRICS_CANCEL_TASKS_LAMBDA_CONNECTION_STRING=var.metrics_cancel_tasks_lambda_connection_string,
    METRICS_TTL_CHECKER_LAMBDA_CONNECTION_STRING=var.metrics_ttl_checker_lambda_connection_string
  }
}

resource "kubernetes_service" "cancel_tasks" {
  metadata {
    name = "cancel-tasks"
  }

  spec {
    selector = {
      app     = kubernetes_deployment.cancel_tasks.metadata.0.labels.app
      service =  kubernetes_deployment.cancel_tasks.metadata.0.labels.service
    }
    type = "LoadBalancer"
    port {
      protocol = "TCP"
      port = var.cancel_tasks_port
      target_port = 8080
      name = "cancel-tasks"
    }
  }
}

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
        image_pull_secrets {
          name = "regcred"
        }

        container {
          image   = var.docker_registry != "" ? "${var.docker_registry}/cancel_tasks:${var.suffix}" : "cancel_tasks:${var.suffix}"
          name    = "cancel-tasks"
          image_pull_policy = var.image_pull_policy != "" ? var.image_pull_policy : "IfNotPresent"

          resources {
            limits = {
              memory = "1024Mi"
            }
          }

          env_from {
            config_map_ref {
              name = kubernetes_config_map.lambda_local.metadata.0.name
              optional = false
            }
          }

          env {
            name = "METRICS_CANCEL_TASKS_LAMBDA_CONNECTION_STRING"
            value =var.metrics_cancel_tasks_lambda_connection_string
          }

          port {
            container_port = 8080
          }
        }
      }
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
      service =  kubernetes_deployment.get_results.metadata.0.labels.service
    }

    type = "LoadBalancer"

    port {
      protocol = "TCP"
      port = var.get_results_port
      target_port = 8080
      name = "get-results"
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
        image_pull_secrets {
          name = "regcred"
        }

        container {
          image   = var.docker_registry != "" ? "${var.docker_registry}/get_results:${var.suffix}" : "get_results:${var.suffix}"
          name    = "get-results"
          image_pull_policy = var.image_pull_policy != "" ? var.image_pull_policy : "IfNotPresent"

          resources {
            limits = {
              memory = "1024Mi"
            }
          }

          env_from {
            config_map_ref {
              name = kubernetes_config_map.lambda_local.metadata.0.name
              optional = false
            }
          }

          env {
            name = "METRICS_GET_RESULTS_LAMBDA_CONNECTION_STRING"
            value =var.metrics_get_results_lambda_connection_string
          }

          port {
            container_port = 8080
          }

          volume_mount {
            name       = "submit-task-volume"
            mount_path = "/redis_certificates"
          }
        }

        volume {
          name = "submit-task-volume"
          host_path {
            path = var.certificates_dir_path
            type = ""
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
        image_pull_secrets {
          name = "regcred"
        }

        container {
          image   = var.docker_registry != "" ? "${var.docker_registry}/submit_tasks:${var.suffix}" : "submit_tasks:${var.suffix}"
          name    = "submit-task"
          image_pull_policy = var.image_pull_policy != "" ? var.image_pull_policy : "IfNotPresent"

          resources {
            limits = {
              memory = "1024Mi"
            }
          }

          env_from {
            config_map_ref {
              name = kubernetes_config_map.lambda_local.metadata.0.name
              optional = false
            }
          }

          env {
            name = "METRICS_SUBMIT_TASKS_LAMBDA_CONNECTION_STRING"
            value =var.metrics_submit_tasks_lambda_connection_string
          }

          port {
            container_port = 8080
          }

          volume_mount {
            name       = "submit-tasks-volume"
            mount_path = "/redis_certificates"
          }
        }

        volume {
          name = "submit-tasks-volume"
          host_path {
            path = var.certificates_dir_path
            type = ""
          }
        }
      }
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
      service =  kubernetes_deployment.submit_task.metadata.0.labels.service
    }
    type = "LoadBalancer"
    port {
      protocol = "TCP"
      port = var.submit_task_port
      target_port = 8080
      name = "submit-task"
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
      service =  kubernetes_deployment.ttl_checker.metadata.0.labels.service
    }
    type = "LoadBalancer"
    port {
      protocol = "TCP"
      port = var.ttl_checker_port
      target_port = 8080
      name = "ttl-checker"
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
        image_pull_secrets {
          name = "regcred"
        }

        container {
          image   = var.docker_registry != "" ? "${var.docker_registry}/ttl_checker:${var.suffix}" : "ttl_checker:${var.suffix}"
          name    = "ttl-checker"
          image_pull_policy = var.image_pull_policy != "" ? var.image_pull_policy : "IfNotPresent"

          resources {
            limits = {
              memory = "1024Mi"
            }
          }

          env_from {
            config_map_ref {
              name = kubernetes_config_map.lambda_local.metadata.0.name
              optional = false
            }
          }

          env {
            name = "METRICS_TTL_CHECKER_LAMBDA_CONNECTION_STRING"
            value =var.metrics_ttl_checker_lambda_connection_string
          }

          port {
            container_port = 8080          
          }
        }
      }
    }
  }
}

resource "kubernetes_cron_job" "ttl_checker_corn_job" {
  depends_on = [
    kubernetes_deployment.ttl_checker
  ]

  metadata {
    name = "ttl-checker-corn-job"
  }

  spec {
    concurrency_policy            = "Replace"
    failed_jobs_history_limit     = 5
    schedule                      = "* * * * *"
    starting_deadline_seconds     = 10
    successful_jobs_history_limit = 10
    job_template {
      metadata {}
      spec {
        backoff_limit              = 2
        ttl_seconds_after_finished = 10
        template {
          metadata {}
          spec {
            container {
              name    = "curl"
              image   = "curlimages/curl:latest"
              args = ["-XPOST", "${local.nginx_pod_ip}:${var.nginx_port}/check", "-d", "{}"]
            }
          }
        }
      }
    }
  }
}