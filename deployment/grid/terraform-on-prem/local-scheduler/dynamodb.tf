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
          image   = "amazon/dynamodb-local:latest"
          name    = "db"
          command = ["java", "-Djava.library.path=./DynamoDBLocal_lib", "-jar", "DynamoDBLocal.jar", "-sharedDb", "-optimizeDbBeforeStartup", "-dbPath", "./data"]

          working_dir = "/home/dynamodblocal"

          port {
            container_port = var.dynamodb_port
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
      port = var.dynamodb_port
      name = "dynamodb"
    }
  }
}