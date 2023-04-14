locals {
  activemq_load_balancer = (kubernetes_service.activemq.spec.0.type == "LoadBalancer" ? {
    ip       = (kubernetes_service.activemq.status.0.load_balancer.0.ingress.0.ip == "" || kubernetes_service.activemq.status.0.load_balancer.0.ingress.0.ip == null ? kubernetes_service.activemq.status.0.load_balancer.0.ingress.0.hostname : kubernetes_service.activemq.status.0.load_balancer.0.ingress.0.ip)
    port     = kubernetes_service.activemq.spec.0.port.0.port
    web_port = kubernetes_service.activemq.spec.0.port.1.port
    } : {
    ip       = ""
    port     = ""
    web_port = ""
  })

  activemq_endpoints = (local.activemq_load_balancer.ip == "" && kubernetes_service.activemq.spec.0.type == "ClusterIP" ? {
    ip       = kubernetes_service.activemq.spec.0.cluster_ip
    port     = kubernetes_service.activemq.spec.0.port.0.port
    web_port = kubernetes_service.activemq.spec.0.port.1.port
    } : {
    ip       = local.activemq_load_balancer.ip
    port     = local.activemq_load_balancer.port
    web_port = local.activemq_load_balancer.web_port
  })

  activemq_url     = "amqp://${local.activemq_endpoints.ip}:${local.activemq_endpoints.port}"
  activemq_web_url = "http://${local.activemq_endpoints.ip}:${local.activemq_endpoints.web_port}"
}

