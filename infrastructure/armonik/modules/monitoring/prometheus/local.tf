# Node IP of prometheus pod
data "external" "prometheus_node_ip" {
  depends_on  = [kubernetes_service.prometheus]
  program     = ["bash", "get_node_ip.sh", "prometheus", var.namespace]
  working_dir = "../utils/scripts"
}

locals {
  prometheus_node_ip = lookup(tomap(data.external.prometheus_node_ip.result), "node_ip", "")
  prometheus_host    = (local.prometheus_node_ip == "" ? kubernetes_service.prometheus.spec.0.cluster_ip : local.prometheus_node_ip)
  prometheus_port    = (local.prometheus_node_ip == "" ? kubernetes_service.prometheus.spec.0.port.0.port : kubernetes_service.prometheus.spec.0.port.0.node_port)
  prometheus_url     = "http://${local.prometheus_host}:${local.prometheus_port}"
}