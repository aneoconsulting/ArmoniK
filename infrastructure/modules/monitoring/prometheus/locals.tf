resource "random_string" "random_resources" {
  length  = 5
  special = false
  upper   = false
  numeric = true
}

locals {
  node_selector_keys   = keys(var.node_selector)
  node_selector_values = values(var.node_selector)

  load_balancer = (kubernetes_service.prometheus.spec.0.type == "LoadBalancer" ? {
    ip   = (kubernetes_service.prometheus.status.0.load_balancer.0.ingress.0.ip == "" ? kubernetes_service.prometheus.status.0.load_balancer.0.ingress.0.hostname : kubernetes_service.prometheus.status.0.load_balancer.0.ingress.0.ip)
    port = kubernetes_service.prometheus.spec.0.port.0.port
    } : {
    ip   = ""
    port = ""
  })

  prometheus_endpoints = (local.load_balancer.ip == "" && kubernetes_service.prometheus.spec.0.type == "ClusterIP" ? {
    ip   = kubernetes_service.prometheus.spec.0.cluster_ip
    port = kubernetes_service.prometheus.spec.0.port.0.port
    } : {
    ip   = local.load_balancer.ip
    port = local.load_balancer.port
  })

  prometheus_url = "http://${local.prometheus_endpoints.ip}:${local.prometheus_endpoints.port}"
}
