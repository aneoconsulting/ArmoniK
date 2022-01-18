# Node IP of Grafana pod
data "external" "grafana_node_ip" {
  depends_on  = [kubernetes_service.grafana]
  program     = ["bash", "get_node_ip.sh", "grafana", var.namespace]
  working_dir = "../utils/scripts"
}

locals {
  grafana_node_ip = lookup(tomap(data.external.grafana_node_ip.result), "node_ip", "")
  grafana_host    = (local.grafana_node_ip == "" ? kubernetes_service.grafana.spec.0.cluster_ip : local.grafana_node_ip)
  grafana_port    = (local.grafana_node_ip == "" ? kubernetes_service.grafana.spec.0.port.0.port : kubernetes_service.grafana.spec.0.port.0.node_port)
  grafana_url     = "http://${local.grafana_host}:${local.grafana_port}"
}