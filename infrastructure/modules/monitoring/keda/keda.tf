resource "helm_release" "keda" {
  name       = "keda"
  namespace  = var.namespace
  chart      = "keda"
  repository = var.helm_chart_repository
  version    = var.helm_chart_version

  set {
    name  = "image.keda.repository"
    value = var.docker_image.keda.image
  }
  set {
    name  = "image.keda.tag"
    value = var.docker_image.keda.tag
  }
  set {
    name  = "image.metricsApiServer.repository"
    value = var.docker_image.metricsApiServer.image
  }
  set {
    name  = "image.metricsApiServer.tag"
    value = var.docker_image.metricsApiServer.tag
  }
  set {
    name  = "imagePullSecrets"
    value = var.image_pull_secrets
  }

  values = [
    yamlencode(local.node_selector),
    yamlencode(local.tolerations)
  ]
}