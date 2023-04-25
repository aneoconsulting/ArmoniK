# rabbitMQ is deployed as a service in Kubernetes create-cluster

# Kubernetes rabbitMQ deployment
resource "kubernetes_deployment" "rabbitmq" {
  metadata {
    name      = "rabbitmq"
    namespace = var.namespace
    labels = {
      app     = "storage"
      type    = "queue"
      service = "rabbitmq"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app     = "storage"
        type    = "queue"
        service = "rabbitmq"
      }
    }
    template {
      metadata {
        name = "rabbitmq"
        labels = {
          app     = "storage"
          type    = "queue"
          service = "rabbitmq"
        }
      }
      spec {
        node_selector = var.rabbitmq.node_selector
        dynamic "toleration" {
          for_each = (var.rabbitmq.node_selector != {} ? [
            for index in range(0, length(local.node_selector_keys)) : {
              key   = local.node_selector_keys[index]
              value = local.node_selector_values[index]
            }
          ] : [])
          content {
            key      = toleration.value.key
            operator = "Equal"
            value    = toleration.value.value
            effect   = "NoSchedule"
          }
        }
        dynamic "image_pull_secrets" {
          for_each = (var.rabbitmq.image_pull_secrets != "" ? [1] : [])
          content {
            name = var.rabbitmq.image_pull_secrets
          }
        }
        container {
          name              = "rabbitmq"
          image             = "${var.rabbitmq.image}:${var.rabbitmq.tag}"
          image_pull_policy = "IfNotPresent"
          env {
            name  = "RABBITMQ_DEFAULT_USER"
            value = random_string.mq_application_user.result
          }
          env {
            name  = "RABBITMQ_DEFAULT_PASS"
            value = random_password.mq_application_password.result
          }
          volume_mount {
            name       = "rabbitmq-storage-secret-volume"
            mount_path = "/credentials/"
            read_only  = true
          }
          volume_mount {
            name       = "rabbitmq-configs"
            mount_path = "/etc/rabbitmq/conf/"
            read_only  = true
          }
          port {
            name           = "rabbitmq"
            container_port = 5672
            protocol       = "TCP"
          }
          port {
            name           = "dashboard"
            container_port = 15672
            protocol       = "TCP"
          }
        }
        volume {
          name = "rabbitmq-storage-secret-volume"
          secret {
            secret_name = kubernetes_secret.rabbitmq_certificate.metadata.0.name
            optional    = false
          }
        }
        volume {
          name = "rabbitmq-configs"
          config_map {
            name     = kubernetes_config_map.rabbitmq_configs.metadata.0.name
            optional = false
          }
        }
      }
    }
  }
}

# Kubernetes rabbitMQ service
resource "kubernetes_service" "rabbitmq" {
  metadata {
    name      = kubernetes_deployment.rabbitmq.metadata.0.name
    namespace = kubernetes_deployment.rabbitmq.metadata.0.namespace
    labels = {
      app     = kubernetes_deployment.rabbitmq.metadata.0.labels.app
      type    = kubernetes_deployment.rabbitmq.metadata.0.labels.type
      service = kubernetes_deployment.rabbitmq.metadata.0.labels.service
    }
  }
  spec {
    type = "ClusterIP"
    selector = {
      app     = kubernetes_deployment.rabbitmq.metadata.0.labels.app
      type    = kubernetes_deployment.rabbitmq.metadata.0.labels.type
      service = kubernetes_deployment.rabbitmq.metadata.0.labels.service
    }
    port {
      name        = "rmq"
      port        = 5672
      target_port = 5672
      protocol    = "TCP"
    }
    port {
      name        = "dashboard"
      port        = 15672
      target_port = 15672
      protocol    = "TCP"
    }
  }
}