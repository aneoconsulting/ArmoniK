# ActiveMQ is deployed as a service in Kubernetes create-cluster

# Kubernetes ActiveMQ deployment
resource "kubernetes_deployment" "activemq" {
  metadata {
    name      = "activemq"
    namespace = var.namespace
    labels    = {
      app     = "storage"
      type    = "queue"
      service = "activemq"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app     = "storage"
        type    = "queue"
        service = "activemq"
      }
    }
    template {
      metadata {
        name   = "activemq"
        labels = {
          app     = "storage"
          type    = "queue"
          service = "activemq"
        }
      }
      spec {
        node_selector = var.activemq.node_selector
        dynamic toleration {
          for_each = (var.activemq.node_selector != {} ? [
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
        dynamic image_pull_secrets {
          for_each = (var.activemq.image_pull_secrets != "" ? [1] : [])
          content {
            name = var.activemq.image_pull_secrets
          }
        }
        container {
          name  = "activemq"
          image = "${var.activemq.image}:${var.activemq.tag}"
          volume_mount {
            name       = "activemq-storage-secret-volume"
            mount_path = "/credentials/"
            read_only  = true
          }
          volume_mount {
            name       = "activemq-jetty-xml"
            mount_path = "/opt/activemq/conf/"
            read_only  = true
          }
          volume_mount {
            name       = "activemq-jolokia-xml"
            mount_path = "/opt/activemq/webapps/api/WEB-INF/classes/"
            read_only  = true
          }
          port {
            name           = "amqp"
            container_port = 5672
            protocol       = "TCP"
          }
          port {
            name           = "dashboard"
            container_port = 8161
            protocol       = "TCP"
          }
        }
        volume {
          name = "activemq-storage-secret-volume"
          secret {
            secret_name = kubernetes_secret.activemq_certificate.metadata.0.name
            optional    = false
          }
        }
        volume {
          name = "activemq-jetty-xml"
          config_map {
            name     = kubernetes_config_map.activemq_configs.metadata.0.name
            optional = false
          }
        }
        volume {
          name = "activemq-jolokia-xml"
          config_map {
            name     = kubernetes_config_map.activemq_jolokia_configs.metadata.0.name
            optional = false
          }
        }
      }
    }
  }
}

# Kubernetes ActiveMQ service
resource "kubernetes_service" "activemq" {
  metadata {
    name      = kubernetes_deployment.activemq.metadata.0.name
    namespace = kubernetes_deployment.activemq.metadata.0.namespace
    labels    = {
      app     = kubernetes_deployment.activemq.metadata.0.labels.app
      type    = kubernetes_deployment.activemq.metadata.0.labels.type
      service = kubernetes_deployment.activemq.metadata.0.labels.service
    }
  }
  spec {
    type     = "ClusterIP"
    selector = {
      app     = kubernetes_deployment.activemq.metadata.0.labels.app
      type    = kubernetes_deployment.activemq.metadata.0.labels.type
      service = kubernetes_deployment.activemq.metadata.0.labels.service
    }
    port {
      name        = "amqp"
      port        = 5672
      target_port = 5672
      protocol    = "TCP"
    }
    port {
      name        = "dashboard"
      port        = 8161
      target_port = 8161
      protocol    = "TCP"
    }
  }
}