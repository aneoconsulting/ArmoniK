
resource "kubernetes_namespace" "chaosmesh" {
  metadata {
    name = var.namespace
  }
}

resource "helm_release" "chaosmesh" {
  name       = "chaosmesh"
  namespace  = kubernetes_namespace.chaosmesh.metadata[0].name
  chart      = "chaos-mesh"
  repository = var.helm_chart_repository
  version    = var.helm_chart_version

  values = var.node_selector != null ? [yamlencode({
    controllerManager = {
      nodeSelector = var.node_selector
    }
    chaosDaemon = {
      nodeSelector = var.node_selector
    }
    dashboard = {
      nodeSelector = var.node_selector
    }
    dnsServer = {
      nodeSelector = var.node_selector
    }
    prometheus = {
      nodeSelector = var.node_selector
    }
  })] : []

  set {
    name  = "image.chaosmesh.repository"
    value = var.docker_image.chaosmesh.image
  }
  set {
    name  = "image.chaosdaemon.tag"
    value = var.docker_image.chaosdaemon.tag
  }
  set {
    name  = "image.chaosdashboard.tag"
    value = var.docker_image.chaosdashboard.tag
  }

  set {
    name  = "dashboard.service.type"
    value = var.service_type
  }
}

data "kubernetes_service" "chaos_dashboard" {
  metadata {
    name      = "chaos-dashboard"
    namespace = var.namespace
  }
  depends_on = [resource.helm_release.chaosmesh]
}
