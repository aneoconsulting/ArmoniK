locals {
  rabbitmq_load_balancer = (kubernetes_service.rabbitmq.spec.0.type == "LoadBalancer" ? {
    ip       = (kubernetes_service.rabbitmq.status.0.load_balancer.0.ingress.0.ip == "" || kubernetes_service.rabbitmq.status.0.load_balancer.0.ingress.0.ip == null ? kubernetes_service.rabbitmq.status.0.load_balancer.0.ingress.0.hostname : kubernetes_service.rabbitmq.status.0.load_balancer.0.ingress.0.ip)
    port     = kubernetes_service.rabbitmq.spec.0.port.0.port
    web_port = kubernetes_service.rabbitmq.spec.0.port.1.port
    } : {
    ip       = ""
    port     = ""
    web_port = ""
  })

  rabbitmq_endpoints = (local.rabbitmq_load_balancer.ip == "" && kubernetes_service.rabbitmq.spec.0.type == "ClusterIP" ? {
    ip       = kubernetes_service.rabbitmq.spec.0.cluster_ip
    port     = kubernetes_service.rabbitmq.spec.0.port.0.port
    web_port = kubernetes_service.rabbitmq.spec.0.port.1.port
    } : {
    ip       = local.rabbitmq_load_balancer.ip
    port     = local.rabbitmq_load_balancer.port
    web_port = local.rabbitmq_load_balancer.web_port
  })

  rabbitmq_url     = "amqp://${local.rabbitmq_endpoints.ip}:${local.rabbitmq_endpoints.port}"
  rabbitmq_web_url = "http://${local.rabbitmq_endpoints.ip}:${local.rabbitmq_endpoints.web_port}"
}

