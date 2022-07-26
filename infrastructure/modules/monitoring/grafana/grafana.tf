# Grafana deployment
resource "kubernetes_deployment" "grafana" {
  metadata {
    name      = "grafana"
    namespace = var.namespace
    labels    = {
      app     = "armonik"
      type    = "logs"
      service = "grafana"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app     = "armonik"
        type    = "logs"
        service = "grafana"
      }
    }
    template {
      metadata {
        name      = "grafana"
        namespace = var.namespace
        labels    = {
          app     = "armonik"
          type    = "logs"
          service = "grafana"
        }
      }
      spec {
        node_selector = var.node_selector
        dynamic toleration {
          for_each = (var.node_selector != {} ? [
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
          for_each = (var.docker_image.image_pull_secrets != "" ? [1] : [])
          content {
            name = var.docker_image.image_pull_secrets
          }
        }
        container {
          name              = "grafana"
          image             = "${var.docker_image.image}:${var.docker_image.tag}"
          image_pull_policy = "IfNotPresent"
          env {
            name  = "discovery.type"
            value = "single-node"
          }
          port {
            name           = "grafana"
            container_port = 3000
            protocol       = "TCP"
          }
          volume_mount {
            name       = "datasources-configmap"
            mount_path = "/etc/grafana/provisioning/datasources/datasources.yml"
            sub_path   = "datasources.yml"
          }
          volume_mount {
            name       = "dashboards-configmap"
            mount_path = "/etc/grafana/provisioning/dashboards/dashboards.yml"
            sub_path   = "dashboards.yml"
          }
          volume_mount {
            name       = "grafana-ini-configmap"
            mount_path = "/etc/grafana/grafana.ini"
            sub_path   = "grafana.ini"
          }
          volume_mount {
            name       = "dashboards-json-configmap"
            mount_path = "/var/lib/grafana/dashboards/"
          }
        }
        volume {
          name = "datasources-configmap"
          config_map {
            name     = kubernetes_config_map.datasources_config.metadata.0.name
            optional = false
          }
        }
        volume {
          name = "dashboards-json-configmap"
          config_map {
            name     = kubernetes_config_map.dashboards_json_config.metadata.0.name
            optional = false
          }
        }
        volume {
          name = "dashboards-configmap"
          config_map {
            name     = kubernetes_config_map.dashboards_config.metadata.0.name
            optional = false
          }
        }
        volume {
          name = "grafana-ini-configmap"
          config_map {
            name     = kubernetes_config_map.grafana_ini.metadata.0.name
            optional = false
          }
        }
      }
    }
  }
}

# Kubernetes grafana service
resource "kubernetes_service" "grafana" {
  metadata {
    name      = kubernetes_deployment.grafana.metadata.0.name
    namespace = kubernetes_deployment.grafana.metadata.0.namespace
    labels    = {
      app     = kubernetes_deployment.grafana.metadata.0.labels.app
      type    = kubernetes_deployment.grafana.metadata.0.labels.type
      service = kubernetes_deployment.grafana.metadata.0.labels.service
    }
  }
  spec {
    type     = var.service_type
    selector = {
      app     = kubernetes_deployment.grafana.metadata.0.labels.app
      type    = kubernetes_deployment.grafana.metadata.0.labels.type
      service = kubernetes_deployment.grafana.metadata.0.labels.service
    }
    port {
      name        = "grafana"
      port        = var.port
      target_port = 3000
      protocol    = "TCP"
    }
  }
}
