# Node IP of ActiveMQ
data "external" "activemq_node_ip" {
  depends_on  = [kubernetes_service.activemq]
  program     = ["bash", "get_node_ip.sh", "activemq", var.namespace]
  working_dir = "${var.working_dir}/utils/scripts"
}

# Node names
locals {
  # ActiveMQ
  activemq_node_ip = lookup(tomap(data.external.activemq_node_ip.result), "node_ip", "")

  activemq_load_balancer = (kubernetes_service.activemq.spec.0.type == "LoadBalancer" ? {
    ip   = (kubernetes_service.activemq.status.0.load_balancer.0.ingress.0.ip == "" || kubernetes_service.activemq.status.0.load_balancer.0.ingress.0.ip == null ? kubernetes_service.activemq.status.0.load_balancer.0.ingress.0.hostname : kubernetes_service.activemq.status.0.load_balancer.0.ingress.0.ip)
    port = kubernetes_service.activemq.spec.0.port.0.port
    web_port = kubernetes_service.activemq.spec.0.port.1.port
  } : {
    ip   = ""
    port = ""
    web_port = ""
  })

  activemq_node_port = (local.activemq_load_balancer.ip == "" && kubernetes_service.activemq.spec.0.type == "NodePort" ? {
    ip   = local.activemq_node_ip
    port = kubernetes_service.activemq.spec.0.port.0.node_port
    web_port = kubernetes_service.activemq.spec.0.port.1.node_port
  } : {
    ip   = local.activemq_load_balancer.ip
    port = local.activemq_load_balancer.port
    web_port = local.activemq_load_balancer.web_port
  })

  activemq_endpoints = (local.activemq_node_port.ip == "" && kubernetes_service.activemq.spec.0.type == "ClusterIP" ? {
    ip   = kubernetes_service.activemq.spec.0.cluster_ip
    port = kubernetes_service.activemq.spec.0.port.0.port
    web_port = kubernetes_service.activemq.spec.0.port.1.port
  } : {
    ip   = local.activemq_node_port.ip
    port = local.activemq_node_port.port
    web_port = local.activemq_node_port.web_port
  })

  activemq_url = "amqp://${local.activemq_endpoints.ip}:${local.activemq_endpoints.port}"
  activemq_web_url = "http://${local.activemq_endpoints.ip}:${local.activemq_endpoints.web_port}"
}

