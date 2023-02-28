resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  namespace  = var.namespace
  chart      = "metrics-server"
  repository = var.helm_chart_repository
  version    = var.helm_chart_version

  set {
    name  = "image.repository"
    value = var.docker_image.image
  }
  set {
    name  = "image.tag"
    value = var.docker_image.tag
  }
  set {
    name  = "imagePullSecrets"
    value = var.image_pull_secrets
  }
  set {
    name  = "hostNetwork.enabled"
    value = var.host_network
  }

  values = [
    yamlencode(local.node_selector),
    yamlencode(local.tolerations),
    yamlencode(local.default_args)
  ]
}