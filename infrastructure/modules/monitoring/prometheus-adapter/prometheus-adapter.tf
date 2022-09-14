resource "helm_release" "prometheus_adapter" {
  name      = "armonik"
  namespace = var.namespace
  chart     = "prometheus-adapter"
  #repository = "https://prometheus-community.github.io/helm-charts"
  repository = "${path.module}/charts"
  version    = "3.0.2"

  set {
    name  = "nameOverride"
    value = local.nameOverride
  }
  set {
    name  = "fullnameOverride"
    value = local.fullnameOverride
  }
  set {
    name  = "image.repository"
    value = var.docker_image.image
  }
  set {
    name  = "image.tag"
    value = var.docker_image.tag
  }
  set {
    name  = "image.pullSecrets"
    value = var.docker_image.image_pull_secrets
  }
  set {
    name  = "prometheus.url"
    value = "http://${var.prometheus_endpoint_url.host}"
  }
  set {
    name  = "prometheus.port"
    value = var.prometheus_endpoint_url.port
  }
  set {
    name  = "serviceAccount.create"
    value = false
  }
  set {
    name  = "serviceAccount.name"
    value = "default"
  }
  set {
    name  = "service.type"
    value = var.service_type
  }

  values = [
    file("${path.module}/manifests/prometheus-rules.yaml"),
    yamlencode(local.node_selector),
    yamlencode(local.tolerations)
  ]
}