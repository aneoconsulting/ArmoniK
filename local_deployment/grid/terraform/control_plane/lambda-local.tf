resource "kubernetes_config_map" "lambda_local" {
  metadata {
    name = "lambda-local"
  }

  data = {
    TASKS_STATUS_TABLE_NAME=aws_dynamodb_table.htc_tasks_status_table.name,
    TASKS_STATUS_TABLE_SERVICE=var.tasks_status_table_service,
    TASKS_STATUS_TABLE_CONFIG=var.tasks_status_table_config,
    TASKS_QUEUE_NAME=aws_sqs_queue.htc_task_queue["__0"].name,
    TASKS_QUEUE_DLQ_NAME=aws_sqs_queue.htc_task_queue_dlq.name,
    METRICS_ARE_ENABLED=var.metrics_are_enabled,
    METRICS_SUBMIT_TASKS_LAMBDA_CONNECTION_STRING=var.metrics_submit_tasks_lambda_connection_string,
    ERROR_LOG_GROUP=var.error_log_group,
    ERROR_LOGGING_STREAM=var.error_logging_stream,
    TASK_INPUT_PASSED_VIA_EXTERNAL_STORAGE = var.task_input_passed_via_external_storage,
    GRID_STORAGE_SERVICE = var.grid_storage_service,
    GRID_QUEUE_SERVICE = var.grid_queue_service,
    GRID_QUEUE_CONFIG = var.grid_queue_config,
    S3_BUCKET = aws_s3_bucket.htc-stdout-bucket.id,
    REDIS_URL = kubernetes_service.redis.status.0.load_balancer.0.ingress.0.ip,
    REDIS_PORT = var.redis_with_ssl ? var.redis_port : var.redis_port_without_ssl,
    METRICS_GRAFANA_PRIVATE_IP = var.nlb_influxdb,
    REGION = var.region,
    AWS_DEFAULT_REGION = var.region,
    AWS_ACCESS_KEY_ID = var.access_key,
    AWS_SECRET_ACCESS_KEY = var.secret_key,
    SQS_ENDPOINT_URL = "http://${kubernetes_service.local_services.status.0.load_balancer.0.ingress.0.ip}:${var.local_services_port}",
    DYNAMODB_ENDPOINT_URL = "http://${kubernetes_service.dynamodb.status.0.load_balancer.0.ingress.0.ip}:${var.dynamodb_port}",
    REDIS_USE_SSL = var.redis_with_ssl,
    REDIS_CERTFILE = var.redis_cert_file,
    REDIS_KEYFILE = var.redis_key_file,
    REDIS_CA_CERT = var.redis_ca_cert,
    USERNAME = var.access_key,
    PASSWORD = var.secret_key,
    AWS_LAMBDA_FUNCTION_TIMEOUT = var.lambda_timeout,
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
          image   = "${var.aws_htc_ecr}/cancel_tasks:${var.suffix}"
          name    = "cancel-tasks"

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
  depends_on = [
    kubernetes_service.local_services,
  ]
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
          image   = "${var.aws_htc_ecr}/get_results:${var.suffix}"
          name    = "get-results"

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
  depends_on = [
    kubernetes_service.local_services,
  ]
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
          image   = "${var.aws_htc_ecr}/submit_tasks:${var.suffix}"
          name    = "submit-task"

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
        }
      }
    }
  }
  depends_on = [
    kubernetes_service.local_services,
  ]
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
          image   = "${var.aws_htc_ecr}/ttl_checker:${var.suffix}"
          name    = "ttl-checker"

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
  depends_on = [
    kubernetes_service.local_services,
  ]
}

resource "kubernetes_cron_job" "ttl_checker_corn_job" {
  depends_on = [
    kubernetes_deployment.ttl_checker,
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
              args = ["-XPOST", "${var.nginx_endpoint_url}:${var.nginx_port}/check", "-d", "{}"]
            }
          }
        }
      }
    }
  }
}