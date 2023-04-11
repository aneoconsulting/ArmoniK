locals {
  node_selector_keys   = keys(var.node_selector)
  node_selector_values = values(var.node_selector)

  load_balancer = (kubernetes_service.grafana.spec.0.type == "LoadBalancer" ? {
    ip   = (kubernetes_service.grafana.status.0.load_balancer.0.ingress.0.ip == "" ? kubernetes_service.grafana.status.0.load_balancer.0.ingress.0.hostname : kubernetes_service.grafana.status.0.load_balancer.0.ingress.0.ip)
    port = kubernetes_service.grafana.spec.0.port.0.port
    } : {
    ip   = ""
    port = ""
  })

  grafana_endpoints = (local.load_balancer.ip == "" && kubernetes_service.grafana.spec.0.type == "ClusterIP" ? {
    ip   = kubernetes_service.grafana.spec.0.cluster_ip
    port = kubernetes_service.grafana.spec.0.port.0.port
    } : {
    ip   = local.load_balancer.ip
    port = local.load_balancer.port
  })

  grafana_url = "http://${local.grafana_endpoints.ip}:${local.grafana_endpoints.port}"
}
