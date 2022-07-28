resource "helm_release" "keda" {
  name       = "metrics-server"
  namespace  = var.namespace
  chart      = "metrics-server"
  repository = "${path.module}/charts"
  version    = "0.1.0"

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

  values = [
    yamlencode(local.node_selector),
    yamlencode(local.tolerations)
  ]
}