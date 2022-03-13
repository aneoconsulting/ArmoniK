# Node IP of Grafana pod
data "external" "grafana_node_ip" {
  depends_on  = [kubernetes_service.grafana]
  program     = ["bash", "get_node_ip.sh", "grafana", var.namespace]
  working_dir = "${var.working_dir}/utils/scripts"
}

locals {
  grafana_node_ip      = lookup(tomap(data.external.grafana_node_ip.result), "node_ip", "")
  node_selector_keys   = keys(var.node_selector)
  node_selector_values = values(var.node_selector)

  load_balancer = (kubernetes_service.grafana.spec.0.type == "LoadBalancer" ? {
    ip   = (kubernetes_service.grafana.status.0.load_balancer.0.ingress.0.ip == "" ? kubernetes_service.grafana.status.0.load_balancer.0.ingress.0.hostname : kubernetes_service.grafana.status.0.load_balancer.0.ingress.0.ip)
    port = kubernetes_service.grafana.spec.0.port.0.port
  } : {
    ip   = ""
    port = ""
  })

  node_port = (local.load_balancer.ip == "" && kubernetes_service.grafana.spec.0.type == "NodePort" ? {
    ip   = local.grafana_node_ip
    port = kubernetes_service.grafana.spec.0.port.0.node_port
  } : {
    ip   = local.load_balancer.ip
    port = local.load_balancer.port
  })

  grafana_endpoints = (local.node_port.ip == "" && kubernetes_service.grafana.spec.0.type == "ClusterIP" ? {
    ip   = kubernetes_service.grafana.spec.0.cluster_ip
    port = kubernetes_service.grafana.spec.0.port.0.port
  } : {
    ip   = local.node_port.ip
    port = local.node_port.port
  })

  grafana_url = "http://${local.grafana_endpoints.ip}:${local.grafana_endpoints.port}"
}
