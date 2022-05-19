# prometheus deployment
resource "kubernetes_deployment" "prometheus" {
  metadata {
    name      = "prometheus"
    namespace = var.namespace
    labels    = {
      app     = "armonik"
      type    = "monitoring"
      service = "prometheus"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app     = "armonik"
        type    = "monitoring"
        service = "prometheus"
      }
    }
    template {
      metadata {
        name      = "prometheus"
        namespace = var.namespace
        labels    = {
          app     = "armonik"
          type    = "monitoring"
          service = "prometheus"
        }
      }
      spec {
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
          name              = "prometheus"
          image             = "${var.docker_image.image}:${var.docker_image.tag}"
          image_pull_policy = "IfNotPresent"
          env {
            name  = "discovery.type"
            value = "single-node"
          }
          port {
            name           = "prometheus"
            container_port = 9090
            protocol       = "TCP"
          }
          volume_mount {
            name       = "prometheus-configmap"
            mount_path = "/etc/prometheus/prometheus.yml"
            sub_path   = "prometheus.yml"
          }
        }
        volume {
          name = "prometheus-configmap"
          config_map {
            name     = kubernetes_config_map.prometheus_config.metadata.0.name
            optional = false
          }
        }
      }
    }
  }
}

# Kubernetes prometheus service
resource "kubernetes_service" "prometheus" {
  metadata {
    name      = kubernetes_deployment.prometheus.metadata.0.name
    namespace = kubernetes_deployment.prometheus.metadata.0.namespace
    labels    = {
      app     = kubernetes_deployment.prometheus.metadata.0.labels.app
      type    = kubernetes_deployment.prometheus.metadata.0.labels.type
      service = kubernetes_deployment.prometheus.metadata.0.labels.service
    }
  }
  spec {
    type     = var.service_type
    selector = {
      app     = kubernetes_deployment.prometheus.metadata.0.labels.app
      type    = kubernetes_deployment.prometheus.metadata.0.labels.type
      service = kubernetes_deployment.prometheus.metadata.0.labels.service
    }
    port {
      name        = "prometheus"
      port        = 9090
      target_port = 9090
      protocol    = "TCP"
    }
  }
}

resource "kubernetes_cluster_role" "prometheus" {
  metadata {
    name   = "${kubernetes_deployment.prometheus.metadata.0.name}-${var.namespace}-${random_string.random_resources.result}"
    labels = {
      app     = "armonik"
      type    = "monitoring"
      service = "prometheus"
    }
  }
  rule {
    api_groups = [""]
    resources  = ["namespaces", "pods", "services", "endpoints", "nodes"]
    verbs      = ["get", "list", "watch"]
  }
  rule {
    non_resource_urls = ["/metrics", "/metrics/cadvisor", "/metrics/resource", "/metrics/probes"]
    verbs             = ["get"]
  }
  rule {
    api_groups = ["networking.k8s.io"]
    resources  = ["ingresses"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_cluster_role_binding" "prometheus" {
  metadata {
    name   = "${kubernetes_deployment.prometheus.metadata.0.name}-${var.namespace}-${random_string.random_resources.result}"
    labels = {
      app     = "armonik"
      type    = "monitoring"
      service = "prometheus"
    }
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.prometheus.metadata.0.name
  }
  # subject {
  #   kind      = "User"
  #   name      = "admin"
  #   api_group = "rbac.authorization.k8s.io"
  # }
  subject {
    kind      = "ServiceAccount"
    name      = "default"
    namespace = var.namespace
  }
  # subject {
  #   kind      = "Group"
  #   name      = "system:masters"
  #   api_group = "rbac.authorization.k8s.io"
  # }
}

resource "kubernetes_cluster_role_binding" "prometheus_ns_armonik" {
  metadata {
    name   = "${kubernetes_deployment.prometheus.metadata.0.name}-${var.namespace}-ns-${random_string.random_resources.result}"
    labels = {
      app     = "armonik"
      type    = "monitoring"
      service = "prometheus"
    }
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.prometheus.metadata.0.name
  }
  subject {
    kind      = "ServiceAccount"
    name      = "default"
    namespace = "armonik"
  }
}