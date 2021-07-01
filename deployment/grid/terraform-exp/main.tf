terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.0"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  access_key                  = "mock_access_key"
  region                      = "eu-central-1"
  secret_key                  = "mock_secret_key"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    dynamodb = "http://localhost:8000"
    cloudwatch = "http://localhost:9000"
    iam = "http://localhost:9000"
  }
}

provider "aws" {
  alias = "aws_htc_task_queue"
  access_key                  = "mock_access_key"
  region                      = "eu-central-1"
  secret_key                  = "mock_secret_key"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    dynamodb = "http://localhost:8000"
    sqs = "http://localhost:8080"
  }
}

provider "aws" {
  alias = "aws_htc_task_queue_dlq"
  access_key                  = "mock_access_key"
  region                      = "eu-central-1"
  secret_key                  = "mock_secret_key"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    dynamodb = "http://localhost:8000"
    sqs = "http://localhost:8081"
  }
}

provider "aws" {
  alias = "aws_cancel_tasks"
  access_key                  = "mock_access_key"
  region                      = "eu-central-1"
  secret_key                  = "mock_secret_key"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    dynamodb = "http://localhost:8000"
    lambda = "http://localhost:9000"
    cloudwatch = "http://localhost:9000"
    cloudwatchlogs = "http://localhost:9000"
    iam = "http://localhost:9000"
  }
}


provider "kubernetes" {
  config_path = "~/.kube/config"
}


resource "kubernetes_stateful_set" "dynamodb" {
  metadata {
    name      = "db"
    labels = {
      app = "armonik"
      service = "db"
    }
  }
  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "armonik"
        service = "db"
      }
    }
    
    service_name = "db"

    template {
      metadata {
        labels = {
          app = "armonik"
          service = "db"
        }
      }

      spec {
        container {
          image   = "amazon/dynamodb-local:latest"
          name    = "db"
          command = ["java", "-Djava.library.path=./DynamoDBLocal_lib", "-jar", "DynamoDBLocal.jar", "-sharedDb", "-optimizeDbBeforeStartup", "-dbPath", "./data"]

          working_dir = "/home/dynamodblocal"

          port {
            container_port = 8000
          }

          volume_mount {
            name       = "status-db"
            mount_path = "/home/dynamodblocal/data"
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
      port = 8000
      name = "db"
    }
  }
}

resource "kubernetes_service" "local_service" {
  metadata {
    name = "local-service"
  }

  spec {
    selector = {
      app     = kubernetes_stateful_set.dynamodb.metadata.0.labels.app
    }
    type = "LoadBalancer"
    port {
      protocol = "TCP"
      port = 8080
      name = "htc-task-queue"
    }

    port {
      protocol = "TCP"
      port = 8081
      name = "htc-task-queue-dlq"
    }

    port {
      protocol = "TCP"
      port = 9000
      name = "cancel-tasks"
    }
  }
}


resource "aws_dynamodb_table" "htc_tasks_status_table" {
  name           = "htc_tasks_status_table"
  read_capacity  = 5
  write_capacity = 5
  
  hash_key       = "task_id"

  depends_on = [kubernetes_service.dynamodb]

  attribute {
    name = "session_id"
    type = "S"
  }

  attribute {
    name = "task_id"
    type = "S"
  }

  # attribute {
  #   name = "submission_timestamp"
  #   type = "N"
  # }

  # attribute {
  #   name = "task_completion_timestamp"
  #   type = "N"
  # }

  attribute {
    name = "task_status"
    type = "S"
  }

  # attribute {
  #   name = "task_owner"
  #   type = "S"
  # }
  # default value "None"

  # attribute {
  #   name = "retries"
  #   type = "N"
  # }

  # attribute {
  #   name = "task_definition"
  #   type = "S"
  # }

  # attribute {
  #   name = "sqs_handler_id"
  #   type = "S"
  # }

  attribute {
    name = "heartbeat_expiration_timestamp"
    type = "N"
  }

  # attribute {
  #   name = "parent_session_id"
  #   type = "S"
  # }
  
  global_secondary_index {
    name               = "gsi_ttl_index"
    hash_key           = "task_status"
    range_key          = "heartbeat_expiration_timestamp"
    read_capacity      = 5
    write_capacity     = 5
    projection_type    = "INCLUDE"
    non_key_attributes = ["task_id", "task_owner"]
  }

  global_secondary_index {
    name               = "gsi_session_index"
    hash_key           = "session_id"
    range_key          = "task_status"
    read_capacity      = 5
    write_capacity     = 5
    projection_type    = "INCLUDE"
    non_key_attributes = ["task_id"]
  }

  # global_secondary_index {
  #   name               = "gsi_parent_session_index"
  #   hash_key           = "parent_session_id"
  #   range_key          = "session_id"
  #   read_capacity      = var.dynamodb_gsi_parent_table_read_capacity
  #   write_capacity     = var.dynamodb_gsi_parent_table_write_capacity
  #   projection_type    = "INCLUDE"
  #   non_key_attributes = ["task_id", "task_status"]
  # }


  tags = {
    service     = "htc-aws"
  }
}


resource "kubernetes_deployment" "htc_task_queue" {
  metadata {
    name      = "htc-task-queue"
    labels = {
      app = "armonik"
      service = "htc-task-queue"
    }
  }
  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "armonik"
        service = "htc-task-queue"
      }
    }
    
    template {
      metadata {
        labels = {
          app = "armonik"
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
            value = 8080
          }
          env {
            name = "DEFAULT_REGION"
            value = "eu-central-1"
          }
          env {
            name = "DEBUG"
            value = "true"
          }

          port {
            container_port = 8080
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
      app = "armonik"
      service = "htc-task-queue-dlq"
    }
  }
  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "armonik"
        service = "htc-task-queue-dlq"
      }
    }
    
    template {
      metadata {
        labels = {
          app = "armonik"
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
            value = 8081
          }
          env {
            name = "DEFAULT_REGION"
            value = "eu-central-1"
          }
          env {
            name = "DEBUG"
            value = "true"
          }

          port {
            container_port = 8081
          }
        }
      }
    }
  }
}


resource "aws_sqs_queue" "htc_task_queue" {
  provider = aws.aws_htc_task_queue
  name = "htc_task_queue"

  depends_on = [kubernetes_service.local_service]

  message_retention_seconds = 1209600 # max 14 days
  visibility_timeout_seconds = 40  # once acquired we should update visibility timeout during processing

}


resource "aws_sqs_queue" "htc_task_queue_dlq" {
  provider = aws.aws_htc_task_queue_dlq
  name = "htc_task_queue_dlq"

  message_retention_seconds = 1209600 # max 14 days

  depends_on = [kubernetes_service.local_service]
}


resource "kubernetes_deployment" "cancel_tasks" {
  metadata {
    name      = "cancel-tasks"
    labels = {
      app = "armonik"
      service = "cancel-tasks"
    }
  }
  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "armonik"
        service = "cancel-tasks"
      }
    }
    
    template {
      metadata {
        labels = {
          app = "armonik"
          service = "cancel-tasks"
        }
      }

      spec {
        container {
          image   = "localstack/localstack:latest"
          name    = "cancel-tasks"

          env {
            name = "SERVICES"
            value = "lambda,cloudwatch,iam"
          }
          env {
            name = "EDGE_PORT"
            value = 9000
          }
          env {
            name = "DEFAULT_REGION"
            value = "eu-central-1"
          }
          env {
            name = "DEBUG"
            value = "true"
          }

          port {
            container_port = 9000
          }
        }
      }
    }
  }
}


module "cancel_tasks" {
  providers = {
    aws = aws.aws_cancel_tasks
  }
  source  = "terraform-aws-modules/lambda/aws"
  depends_on = [kubernetes_service.local_service]

  attach_cloudwatch_logs_policy = false


  version = "v1.48.0"
  source_path = [
    "../../../source/control_plane/python/lambda/cancel_tasks",
    {
      path = "../../../source/client/python/api-v0.1/"
      patterns = [
        "!README\\.md",
        "!setup\\.py",
        "!LICENSE*",
      ]
    },
    {
      path = "../../../source/client/python/utils/"
      patterns = [
        "!README\\.md",
        "!setup\\.py",
        "!LICENSE*",
      ]
    },
    {
      pip_requirements = "../../../source/control_plane/python/lambda/cancel_tasks/requirements.txt"
    }
  ]
  function_name = "cancel_tasks" # "var.lambda_name_cancel_tasks"
  #build_in_docker = true
  #docker_image = "${var.aws_htc_ecr}/lambda-build:build-${var.lambda_runtime}"
  handler = "cancel_tasks.lambda_handler"
  memory_size = 1024
  timeout = 300
  runtime = "python3.8" #var.lambda_runtime
  create_role = false
  #lambda_role = aws_iam_role.role_lambda_cancel_tasks.arn

  #vpc_subnet_ids = var.vpc_private_subnet_ids
  #vpc_security_group_ids = [var.vpc_default_security_group_id]

  # environment_variables  = {
  #  TASKS_STATUS_TABLE_NAME=aws_dynamodb_table.htc_tasks_status_table.name,
  #  TASKS_QUEUE_NAME=aws_sqs_queue.htc_task_queue.name,
  #  TASKS_QUEUE_DLQ_NAME=aws_sqs_queue.htc_task_queue_dlq.name,
  #  METRICS_ARE_ENABLED=var.metrics_are_enabled,
  #  METRICS_CANCEL_TASKS_LAMBDA_CONNECTION_STRING=var.metrics_cancel_tasks_lambda_connection_string,
  #  ERROR_LOG_GROUP=var.error_log_group,
  #  ERROR_LOGGING_STREAM=var.error_logging_stream,
  #  TASK_INPUT_PASSED_VIA_EXTERNAL_STORAGE = var.task_input_passed_via_external_storage,
  #  GRID_STORAGE_SERVICE = var.grid_storage_service,
  #  S3_BUCKET = aws_s3_bucket.htc-stdout-bucket.id,
  #  REDIS_URL = aws_elasticache_cluster.stdin-stdout-cache.cache_nodes.0.address,
  #  METRICS_GRAFANA_PRIVATE_IP = var.nlb_influxdb,
  #  REGION = var.region
  # }

   tags = {
    service     = "htc-grid"
  }
  #depends_on = [aws_iam_role_policy_attachment.lambda_logs_attachment, aws_cloudwatch_log_group.cancel_tasks_logs]
}

resource "aws_cloudwatch_log_group" "global_error_group" {
   name = "global_error_group"
   retention_in_days = 14
   provider = aws.aws_cancel_tasks
}
