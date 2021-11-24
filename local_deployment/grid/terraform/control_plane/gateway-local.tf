resource "kubernetes_namespace" "nginx_namespace" {
  metadata {
    name   = "ingress-nginx"
    labels = {
      "app.kubernetes.io/name"       = "ingress-nginx"
      "app.kubernetes.io/instance"   = "ingress-nginx"
      "app.kubernetes.io/version"    = "1.0.4"
      "app.kubernetes.io/managed-by" = "terraform"
      "app.kubernetes.io/component"  = "controller"
    }
  }
}

resource kubernetes_service_account "nginx_ingress_service_account" {
  metadata {
    name      = "ingress-nginx"
    namespace = kubernetes_namespace.nginx_namespace.metadata.0.name
    labels    = {
      "app.kubernetes.io/name"       = "ingress-nginx"
      "app.kubernetes.io/instance"   = "ingress-nginx"
      "app.kubernetes.io/version"    = "1.0.4"
      "app.kubernetes.io/managed-by" = "terraform"
      "app.kubernetes.io/component"  = "controller"
    }
  }
  automount_service_account_token = true
}

resource "kubernetes_config_map" "nginx_ingress_configmap" {
  metadata {
    name      = "ingress-nginx-controller"
    namespace = kubernetes_namespace.nginx_namespace.metadata.0.name
    labels    = {
      "app.kubernetes.io/name"       = "ingress-nginx"
      "app.kubernetes.io/instance"   = "ingress-nginx"
      "app.kubernetes.io/version"    = "1.0.4"
      "app.kubernetes.io/managed-by" = "terraform"
      "app.kubernetes.io/component"  = "controller"
    }
  }
  data = {
    "allow-snippet-annotations" = "true"
  }
}

resource "kubernetes_cluster_role" "nginx_ingress_cluster_role" {
  metadata {
    name   = "ingress-nginx"
    labels = {
      "app.kubernetes.io/name"       = "ingress-nginx"
      "app.kubernetes.io/instance"   = "ingress-nginx"
      "app.kubernetes.io/version"    = "1.0.4"
      "app.kubernetes.io/managed-by" = "terraform"
      "app.kubernetes.io/component"  = "controller"
    }
  }

  rule {
    api_groups = [""]
    resources  = ["configmaps", "endpoints", "nodes", "pods", "secrets"]
    verbs      = ["list", "watch"]
  }

  rule {
    api_groups = [""]
    resources  = ["nodes"]
    verbs      = ["get"]
  }

  rule {
    api_groups = [""]
    resources  = ["services"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["networking.k8s.io"]
    resources  = ["ingresses"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = [""]
    resources  = ["events"]
    verbs      = ["create", "patch"]
  }

  rule {
    api_groups = ["networking.k8s.io"]
    resources  = ["ingresses/status"]
    verbs      = ["update"]
  }

  rule {
    api_groups = ["networking.k8s.io"]
    resources  = ["ingressclasses"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_cluster_role_binding" "nginx_ingress_cluster_role_binding" {
  metadata {
    name   = "ingress-nginx"
    labels = {
      "app.kubernetes.io/name"       = "ingress-nginx"
      "app.kubernetes.io/instance"   = "ingress-nginx"
      "app.kubernetes.io/version"    = "1.0.4"
      "app.kubernetes.io/managed-by" = "terraform"
      "app.kubernetes.io/component"  = "controller"
    }
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.nginx_ingress_cluster_role.metadata.0.name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.nginx_ingress_service_account.metadata.0.name
    namespace = kubernetes_namespace.nginx_namespace.metadata.0.name
  }
}

resource "kubernetes_role" "nginx_ingress_controller_role" {
  metadata {
    name      = "ingress-nginx"
    namespace = kubernetes_namespace.nginx_namespace.metadata.0.name
    labels    = {
      "app.kubernetes.io/name"       = "ingress-nginx"
      "app.kubernetes.io/instance"   = "ingress-nginx"
      "app.kubernetes.io/version"    = "1.0.4"
      "app.kubernetes.io/managed-by" = "terraform"
      "app.kubernetes.io/component"  = "controller"
    }
  }

  rule {
    api_groups = [""]
    resources  = ["namespaces"]
    verbs      = ["get"]
  }

  rule {
    api_groups = [""]
    resources  = ["configmaps", "endpoints", "pods", "secrets"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = [""]
    resources  = ["services"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["networking.k8s.io"]
    resources  = ["ingresses"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["networking.k8s.io"]
    resources  = ["ingresses/status"]
    verbs      = ["update"]
  }

  rule {
    api_groups = ["networking.k8s.io"]
    resources  = ["ingressclasses"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups     = [""]
    resources      = ["configmaps"]
    resource_names = ["ingress-controller-leader"]
    verbs          = ["get", "update"]
  }

  rule {
    api_groups = [""]
    resources  = ["configmaps"]
    verbs      = ["create"]
  }

  rule {
    api_groups = [""]
    resources  = ["events"]
    verbs      = ["create", "patch"]
  }
}

resource "kubernetes_role_binding" "nginx_ingress_role_binding" {
  metadata {
    name      = "ingress-nginx"
    namespace = kubernetes_namespace.nginx_namespace.metadata.0.name
    labels    = {
      "app.kubernetes.io/name"       = "ingress-nginx"
      "app.kubernetes.io/instance"   = "ingress-nginx"
      "app.kubernetes.io/version"    = "1.0.4"
      "app.kubernetes.io/managed-by" = "terraform"
      "app.kubernetes.io/component"  = "controller"
    }
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.nginx_ingress_controller_role.metadata.0.name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.nginx_ingress_service_account.metadata.0.name
    namespace = kubernetes_namespace.nginx_namespace.metadata.0.name
  }
}

resource "kubernetes_deployment" "nginx_ingress_controller_deployment" {
  metadata {
    name      = "ingress-nginx-controller"
    namespace = kubernetes_namespace.nginx_namespace.metadata.0.name
    labels    = {
      "app.kubernetes.io/name"       = "ingress-nginx"
      "app.kubernetes.io/instance"   = "ingress-nginx"
      "app.kubernetes.io/version"    = "1.0.4"
      "app.kubernetes.io/managed-by" = "terraform"
      "app.kubernetes.io/component"  = "controller"
    }
  }

  spec {
    selector {
      match_labels = {
        "app.kubernetes.io/name"      = "ingress-nginx"
        "app.kubernetes.io/instance"  = "ingress-nginx"
        "app.kubernetes.io/component" = "controller"
      }
    }
    revision_history_limit = 10
    min_ready_seconds      = 0
    template {
      metadata {
        labels = {
          "app.kubernetes.io/name" : "ingress-nginx"
          "app.kubernetes.io/instance" : "ingress-nginx"
          "app.kubernetes.io/component" : "controller"
        }
      }
      spec {
        dns_policy = "ClusterFirst"
        container {
          name              = "controller"
          image             = "k8s.gcr.io/ingress-nginx/controller:v1.0.4@sha256:545cff00370f28363dad31e3b59a94ba377854d3a11f18988f5f9e56841ef9ef"
          image_pull_policy = "IfNotPresent"
          lifecycle {
            pre_stop {
              exec {
                command = ["/wait-shutdown"]
              }
            }
          }
          args              = [
            "/nginx-ingress-controller",
            "--configmap=$(POD_NAMESPACE)/${kubernetes_config_map.nginx_ingress_configmap.metadata.0.name}",
            "--publish-service=$(POD_NAMESPACE)/${var.nginx_ingress_name}",
            "--election-id=ingress-controller-leader",
            "--controller-class=k8s.io/ingress-nginx"
          ]
          security_context {
            capabilities {
              drop = ["ALL"]
              add  = ["NET_BIND_SERVICE"]
            }
            run_as_user                = "101"
            allow_privilege_escalation = true
          }

          env {
            name = "POD_NAME"
            value_from {
              field_ref {
                field_path = "metadata.name"
              }
            }
          }
          env {
            name = "POD_NAMESPACE"
            value_from {
              field_ref {
                field_path = "metadata.namespace"
              }
            }
          }
          env {
            name  = "LD_PRELOAD"
            value = "/usr/local/lib/libmimalloc.so"
          }

          liveness_probe {
            failure_threshold     = 5
            http_get {
              path   = "/healthz"
              port   = "10254"
              scheme = "HTTP"
            }
            initial_delay_seconds = 10
            period_seconds        = 10
            success_threshold     = 1
            timeout_seconds       = 1
          }

          readiness_probe {
            failure_threshold     = 3
            http_get {
              path   = "/healthz"
              port   = "10254"
              scheme = "HTTP"
            }
            initial_delay_seconds = 10
            period_seconds        = 10
            success_threshold     = 1
            timeout_seconds       = 1
          }

          port {
            name           = "http"
            container_port = var.nginx_port
            protocol       = "TCP"
          }
          port {
            name           = "https"
            container_port = var.nginx_ssl_port
            protocol       = "TCP"
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "90Mi"
            }
          }
          volume_mount {
            mount_path = "/var/run/secrets/kubernetes.io/serviceaccount"
            name       = kubernetes_service_account.nginx_ingress_service_account.default_secret_name
            read_only  = true
          }
        }

        node_selector = {
          "kubernetes.io/os" = "linux"
        }

        service_account_name             = kubernetes_service_account.nginx_ingress_service_account.metadata.0.name
        termination_grace_period_seconds = 300
        volume {
          name = kubernetes_service_account.nginx_ingress_service_account.default_secret_name

          secret {
            secret_name = kubernetes_service_account.nginx_ingress_service_account.default_secret_name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "nginx_ingress_controller_service" {
  metadata {
    name      = var.nginx_ingress_name
    namespace = kubernetes_namespace.nginx_namespace.metadata.0.name
    labels    = {
      "app.kubernetes.io/name"       = "ingress-nginx"
      "app.kubernetes.io/instance"   = "ingress-nginx"
      "app.kubernetes.io/version"    = "1.0.4"
      "app.kubernetes.io/managed-by" = "terraform"
      "app.kubernetes.io/component"  = "controller"
    }
  }
  spec {
    type                    = "LoadBalancer"
    external_traffic_policy = "Local"

    port {
      name        = "http"
      port        = var.nginx_port
      protocol    = "TCP"
      target_port = 80
    }

    port {
      name        = "https"
      port        = var.nginx_ssl_port
      protocol    = "TCP"
      target_port = 443
    }

    selector = {
      "app.kubernetes.io/name"      = "ingress-nginx"
      "app.kubernetes.io/instance"  = "ingress-nginx"
      "app.kubernetes.io/component" = "controller"
    }
  }
}

resource "kubernetes_ingress_class" "controller_ingress_class" {
  metadata {
    name   = "nginx"
    labels = {
      "helm.sh/chart"                = "ingress-nginx-4.0.6"
      "app.kubernetes.io/name"       = "ingress-nginx"
      "app.kubernetes.io/instance"   = "ingress-nginx"
      "app.kubernetes.io/version"    = "1.0.4"
      "app.kubernetes.io/managed-by" = "Helm"
      "app.kubernetes.io/component"  = "controller"
    }
  }

  spec {
    controller = "k8s.io/ingress-nginx"
  }
}


resource "kubernetes_ingress" "lambda_local" {
  depends_on = [
    kubernetes_service.cancel_tasks,
    kubernetes_service.submit_task,
    kubernetes_service.get_results,
    kubernetes_service.ttl_checker,
    kubernetes_deployment.nginx_ingress_controller_deployment
  ]

  metadata {
    name        = "lambda-local"
    annotations = {
      "kubernetes.io/ingress.class"                       = kubernetes_ingress_class.controller_ingress_class.metadata.0.name
      "nginx.ingress.kubernetes.io/rewrite-target"        = "/2015-03-31/functions/function/invocations$1"
      "nginx.ingress.kubernetes.io/configuration-snippet" = "more_set_headers \"Content-Type: application/json\";"
    }
  }

  spec {
    rule {
      http {
        path {
          path = "/cancel(.*)"
          backend {
            service_name = kubernetes_service.cancel_tasks.metadata.0.name
            service_port = var.cancel_tasks_port
          }
        }
      }
    }

    rule {
      http {
        path {
          path = "/submit(.*)"
          backend {
            service_name = kubernetes_service.submit_task.metadata.0.name
            service_port = var.submit_task_port
          }
        }
      }
    }

    rule {
      http {
        path {
          path = "/result(.*)"
          backend {
            service_name = kubernetes_service.get_results.metadata.0.name
            service_port = var.get_results_port
          }
        }
      }
    }

    rule {
      http {
        path {
          path = "/check(.*)"
          backend {
            service_name = kubernetes_service.ttl_checker.metadata.0.name
            service_port = var.ttl_checker_port
          }
        }
      }
    }
  }
}