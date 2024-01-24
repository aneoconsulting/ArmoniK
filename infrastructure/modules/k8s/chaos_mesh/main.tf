
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

  # commented coz it crash with the error : 
  #                        var.node_selector is object with no attributes
  #                        Inappropriate value for attribute "value": string required

  #set {
  #  name  = "controllerManager.nodeSelector"
  #  value = var.node_selector
  #}

  #set {
  #  name  = "chaosDaemon.nodeSelector"
  #  value = var.node_selector
  #}

  #set {
  #  name  = "dashboard.nodeSelector"
  #  value = var.node_selector
  #}

  #set {
  #  name  = "dnsServer.nodeSelector"
  #  value = var.node_selector
  #}

  #set {
  #  name  = "prometheus.nodeSelector"
  #  value = var.node_selector
  #}

}

data "kubernetes_service" "chaos_dashboard" {
  metadata {
    name      = "chaos-dashboard"
    namespace = var.namespace
  }
  depends_on = [resource.helm_release.chaosmesh]
}
