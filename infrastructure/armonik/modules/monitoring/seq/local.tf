# Node IP of seq pod
data "external" "seq_node_ip" {
  depends_on  = [kubernetes_service.seq]
  program     = ["bash", "get_node_ip.sh", "seq", var.namespace]
  working_dir = "../utils/scripts"
}

locals {
  seq_node_ip = lookup(tomap(data.external.seq_node_ip.result), "node_ip", "")

  load_balancer = (kubernetes_service.seq.spec.0.type == "LoadBalancer" ? {
    ip           = (kubernetes_service.seq.status.0.load_balancer.0.ingress.0.ip == "" ? kubernetes_service.seq.status.0.load_balancer.0.ingress.0.hostname : kubernetes_service.seq.status.0.load_balancer.0.ingress.0.ip)
    seq_port     = kubernetes_service.seq.spec.0.port.0.port
    seq_web_port = kubernetes_service.seq.spec.0.port.1.port
  } : {
    ip           = ""
    seq_port     = ""
    seq_web_port = ""
  })

  node_port = (local.load_balancer.ip == "" && kubernetes_service.seq.spec.0.type == "NodePort" ? {
    ip           = local.seq_node_ip
    seq_port     = kubernetes_service.seq.spec.0.port.0.node_port
    seq_web_port = kubernetes_service.seq.spec.0.port.1.node_port
  } : {
    ip           = local.load_balancer.ip
    seq_port     = local.load_balancer.seq_port
    seq_web_port = local.load_balancer.seq_web_port
  })

  seq_endpoints = (local.node_port.ip == "" && kubernetes_service.seq.spec.0.type == "ClusterIP" ? {
    ip           = kubernetes_service.seq.spec.0.cluster_ip
    seq_port     = kubernetes_service.seq.spec.0.port.0.port
    seq_web_port = kubernetes_service.seq.spec.0.port.1.port
  } : {
    ip           = local.node_port.ip
    seq_port     = local.node_port.seq_port
    seq_web_port = local.node_port.seq_web_port
  })

  seq_url     = "http://${local.seq_endpoints.ip}:${local.seq_endpoints.seq_port}"
  seq_web_url = "http://${local.seq_endpoints.ip}:${local.seq_endpoints.seq_web_port}"
}