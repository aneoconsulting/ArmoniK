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
          volume_mount {
            name       = "rabbitmq-plugins"
            mount_path = "/etc/rabbitmq"
            read_only  = true
          }
          # volume_mount {
          #   name       = "rabbitmq-config"
          #   mount_path = "/etc/rabbitmq/conf.d/"
          #   read_only  = true
          # }
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
          name = "rabbitmq-plugins"
          config_map {
            name     = kubernetes_config_map.rabbitmq_plugins.metadata.0.name
            optional = false
          }
        }
        # volume {
        #   name = "rabbitmq-config"
        #   config_map {
        #     name     = kubernetes_config_map.rabbitmq_config.metadata.0.name
        #     optional = false
        #   }
        # }
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