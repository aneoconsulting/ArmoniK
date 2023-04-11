locals {
  node_selector_keys   = keys(var.node_selector)
  node_selector_values = values(var.node_selector)

  load_balancer = (kubernetes_service.seq_web_console.spec.0.type == "LoadBalancer" ? {
    ip           = (kubernetes_service.seq_web_console.status.0.load_balancer.0.ingress.0.ip == "" ? kubernetes_service.seq_web_console.status.0.load_balancer.0.ingress.0.hostname : kubernetes_service.seq_web_console.status.0.load_balancer.0.ingress.0.ip)
    seq_web_port = kubernetes_service.seq_web_console.spec.0.port.0.port
    } : {
    ip           = ""
    seq_web_port = ""
  })

  seq_endpoints = (local.load_balancer.ip == "" && kubernetes_service.seq_web_console.spec.0.type == "ClusterIP" ? {
    ip           = kubernetes_service.seq_web_console.spec.0.cluster_ip
    seq_web_port = kubernetes_service.seq_web_console.spec.0.port.0.port
    } : {
    ip           = local.load_balancer.ip
    seq_web_port = local.load_balancer.seq_web_port
  })


  seq_url     = "http://${kubernetes_service.seq.spec.0.cluster_ip}:${kubernetes_service.seq.spec.0.port.0.port}"
  seq_web_url = "http://${local.seq_endpoints.ip}:${local.seq_endpoints.seq_web_port}"
}
