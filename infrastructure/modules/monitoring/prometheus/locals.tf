resource "random_string" "random_resources" {
  length  = 5
  special = false
  upper   = false
  numeric = true
}

# Node IP of prometheus pod
data "external" "prometheus_node_ip" {
  depends_on  = [kubernetes_service.prometheus]
  program     = ["bash", "get_node_ip.sh", "prometheus", var.namespace]
  working_dir = "${var.working_dir}/utils/scripts"
}

locals {
  prometheus_node_ip   = try(tomap(data.external.prometheus_node_ip.result).node_ip, "")
  node_selector_keys   = keys(var.node_selector)
  node_selector_values = values(var.node_selector)

  load_balancer = (kubernetes_service.prometheus.spec.0.type == "LoadBalancer" ? {
    ip   = (kubernetes_service.prometheus.status.0.load_balancer.0.ingress.0.ip == "" ? kubernetes_service.prometheus.status.0.load_balancer.0.ingress.0.hostname : kubernetes_service.prometheus.status.0.load_balancer.0.ingress.0.ip)
    port = kubernetes_service.prometheus.spec.0.port.0.port
    } : {
    ip   = ""
    port = ""
  })

  node_port = (local.load_balancer.ip == "" && kubernetes_service.prometheus.spec.0.type == "NodePort" ? {
    ip   = local.prometheus_node_ip
    port = kubernetes_service.prometheus.spec.0.port.0.node_port
    } : {
    ip   = local.load_balancer.ip
    port = local.load_balancer.port
  })

  prometheus_endpoints = (local.node_port.ip == "" && kubernetes_service.prometheus.spec.0.type == "ClusterIP" ? {
    ip   = kubernetes_service.prometheus.spec.0.cluster_ip
    port = kubernetes_service.prometheus.spec.0.port.0.port
    } : {
    ip   = local.node_port.ip
    port = local.node_port.port
  })

  prometheus_url = "http://${local.prometheus_endpoints.ip}:${local.prometheus_endpoints.port}"
}
