resource "kubernetes_deployment" "dashboard_metrics_scraper" {
  metadata {
    name      = "dashboard-metrics-scraper"
    namespace = var.namespace
    labels    = {
      app     = "armonik"
      type    = "logs"
      service = "dashboard-metrics-scraper"
    }
  }
  spec {
    replicas               = var.dashboard_metrics_scraper.replicas
    revision_history_limit = 10
    selector {
      match_labels = {
        service = "dashboard-metrics-scraper"
      }
    }
    template {
      metadata {
        labels = {
          service = "dashboard-metrics-scraper"
        }
      }
      spec {
        security_context {}
        container {
          name  = "dashboard-metrics-scraper"
          image = "kubernetesui/metrics-scraper:v1.0.7"
          port {
            container_port = var.dashboard_metrics_scraper.port.target_port
            protocol       = var.dashboard_metrics_scraper.port.protocol
          }
          liveness_probe {
            http_get {
              scheme = "HTTP"
              path   = "/"
              port   = var.dashboard_metrics_scraper.port.target_port
            }
            initial_delay_seconds = 30
            timeout_seconds       = 30
          }
          volume_mount {
            name       = "tmp-volume"
            mount_path = "/tmp"
          }
          security_context {
            allow_privilege_escalation = false
            read_only_root_filesystem  = true
            run_as_user                = 1001
            run_as_group               = 2001
          }
        }
        service_account_name = data.kubernetes_service_account.kubernetes_dashboard_service_account.metadata.0.name
        node_selector        = {
          "kubernetes.io/os" = "linux"
        }
        # Comment the following tolerations if Dashboard must not be deployed on master
        toleration {
          key    = "node-role.kubernetes.io/master"
          effect = "NoSchedule"
        }
        volume {
          name = "tmp-volume"
          empty_dir {}
        }
      }
    }
  }
}

resource "kubernetes_service" "dashboard_metrics_scraper" {
  metadata {
    name      = "dashboard-metrics-scraper"
    namespace = var.namespace
    labels    = {
      app     = "armonik"
      type    = "logs"
      service = "dashboard-metrics-scraper"
    }
  }
  spec {
    port {
      port        = var.dashboard_metrics_scraper.port.port
      target_port = var.dashboard_metrics_scraper.port.target_port
    }
    selector = {
      service = "dashboard-metrics-scraper"
    }
  }
}