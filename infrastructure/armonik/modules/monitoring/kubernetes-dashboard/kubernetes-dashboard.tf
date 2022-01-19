resource "kubernetes_deployment" "kubernetes_dashboard" {
  metadata {
    name      = "kubernetes-dashboard"
    namespace = var.namespace
    labels    = {
      app     = "armonik"
      type    = "logs"
      service = "kubernetes-dashboard"
    }
  }
  spec {
    replicas               = var.kubernetes_dashboard.replicas
    revision_history_limit = 10
    selector {
      match_labels = {
        service = "kubernetes-dashboard"
      }
    }
    template {
      metadata {
        labels = {
          service = "kubernetes-dashboard"
        }
      }
      spec {
        container {
          name              = "kubernetes-dashboard"
          image             = "kubernetesui/dashboard:v2.4.0"
          image_pull_policy = "Always"
          port {
            container_port = var.kubernetes_dashboard.port.target_port
            protocol       = var.kubernetes_dashboard.port.protocol
          }
          args              = [
            "--auto-generate-certificates",
            "--namespace=${var.namespace}",
            # Uncomment the following line to manually specify Kubernetes API server Host
            # If not specified, Dashboard will attempt to auto discover the API server and connect
            # to it. Uncomment only if the default does not work.
            # "--apiserver-host=http://my-address:port"
          ]
          volume_mount {
            name       = "kubernetes-dashboard-certs"
            mount_path = "/certs"
          }
          volume_mount {
            # Create on-disk volume to store exec logs
            name       = "tmp-volume"
            mount_path = "/tmp"
          }
          liveness_probe {
            http_get {
              scheme = "HTTPS"
              path   = "/"
              port   = var.kubernetes_dashboard.port.target_port
            }
            initial_delay_seconds = 30
            timeout_seconds       = 30
          }
          security_context {
            allow_privilege_escalation = false
            read_only_root_filesystem  = true
            run_as_user                = 1001
            run_as_group               = 2001
          }
        }
        volume {
          name = "kubernetes-dashboard-certs"
          secret {
            secret_name = kubernetes_secret.kubernetes_dashboard_certs.metadata.0.name
          }
        }
        volume {
          name = "tmp-volume"
          empty_dir {}
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
      }
    }
  }
}

resource "kubernetes_service" "kubernetes_dashboard" {
  metadata {
    name      = "kubernetes-dashboard"
    namespace = var.namespace
    labels    = {
      app     = "armonik"
      type    = "logs"
      service = "kubernetes-dashboard"
    }
  }
  spec {
    port {
      port        = var.kubernetes_dashboard.port.port
      target_port = var.kubernetes_dashboard.port.target_port
    }
    selector = {
      service = "kubernetes-dashboard"
    }
  }
}