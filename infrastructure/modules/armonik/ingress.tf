resource "helm_release" "ingress_nginx" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "3.15.2"
  namespace  = var.namespace
  timeout    = 300

  values = [<<-EOF
    controller:
      admissionWebhooks:
        enabled: false
      electionID: ingress-controller-leader-internal
      ingressClass: nginx-${var.namespace}
      podLabels:
        app: ingress-nginx
      service:
        annotations:
          service.beta.kubernetes.io/aws-load-balancer-type: nlb
      scope:
        enabled: true
    rbac:
      scope: true
    EOF
  ]
}

resource "kubernetes_ingress" "ingress" {
  metadata {
    labels = {
      app = "ingress-nginx"
    }
    name = "api-ingress"
    namespace = var.namespace
    annotations = {
      "kubernetes.io/ingress.class": "nginx-${var.namespace}"
    }
  }

  spec {
    rule {
      http {
        path {
          path = "/"
          backend {
            service_name = kubernetes_service.control_plane.metadata.0.name
            service_port = kubernetes_service.control_plane.spec.0.port.0.port
          }
        }
      }
    }
  }
}
