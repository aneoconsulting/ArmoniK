locals {
  redis_load_balancer = (kubernetes_service.redis.spec.0.type == "LoadBalancer" ? {
    ip   = (kubernetes_service.redis.status.0.load_balancer.0.ingress.0.ip == "" || kubernetes_service.redis.status.0.load_balancer.0.ingress.0.ip == null ? kubernetes_service.redis.status.0.load_balancer.0.ingress.0.hostname : kubernetes_service.redis.status.0.load_balancer.0.ingress.0.ip)
    port = kubernetes_service.redis.spec.0.port.0.port
    } : {
    ip   = ""
    port = ""
  })

  redis_endpoints = (local.redis_load_balancer.ip == "" && kubernetes_service.redis.spec.0.type == "ClusterIP" ? {
    ip   = kubernetes_service.redis.spec.0.cluster_ip
    port = kubernetes_service.redis.spec.0.port.0.port
    } : {
    ip   = local.redis_load_balancer.ip
    port = local.redis_load_balancer.port
  })

  redis_url = "${local.redis_endpoints.ip}:${local.redis_endpoints.port}"
}

