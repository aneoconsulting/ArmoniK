# Node IP of prometheus pod
data "external" "prometheus_node_ip" {
  depends_on  = [kubernetes_service.prometheus]
  program     = ["bash", "get_node_ip.sh", "prometheus", var.namespace]
  working_dir = "../utils/scripts"
}

locals {
  prometheus_node_ip  = lookup(tomap(data.external.prometheus_node_ip.result), "node_ip", "")
  prometheus_host     = (kubernetes_service.prometheus.spec.0.type == "LoadBalancer" ? kubernetes_service.prometheus.status.0.load_balancer.0.ingress.0.ip : (kubernetes_service.prometheus.spec.0.type == "NodePort" && local.prometheus_node_ip != "" ? local.prometheus_node_ip : kubernetes_service.prometheus.spec.0.cluster_ip))
  prometheus_port     = (kubernetes_service.prometheus.spec.0.type == "NodePort" && local.prometheus_node_ip != "" ? kubernetes_service.prometheus.spec.0.port.0.node_port : kubernetes_service.prometheus.spec.0.port.0.port)
  prometheus_url      = "http://${local.prometheus_host}:${local.prometheus_port}"
}