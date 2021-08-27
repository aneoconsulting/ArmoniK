resource "kubectl_manifest" "ingress-nginx" {
    count     = length(var.kubectl_path_documents.documents)
    yaml_body = element(var.kubectl_path_documents.documents, count.index)
}

resource "kubernetes_ingress" "lambda_local" {
  depends_on = [
    kubectl_manifest.ingress-nginx,
    kubernetes_service.cancel_tasks,
    kubernetes_service.submit_task,
    kubernetes_service.get_results,
    kubernetes_service.ttl_checker
  ]

  metadata {
    name = "lambda-local"
    annotations = {
        "kubernetes.io/ingress.class" = "nginx"
        "nginx.ingress.kubernetes.io/rewrite-target" = "/2015-03-31/functions/function/invocations$1"
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