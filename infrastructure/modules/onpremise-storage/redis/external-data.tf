# Node IP of Redis pod
data "external" "redis_node_ip" {
  depends_on  = [kubernetes_service.redis]
  program     = ["bash", "get_node_ip.sh", "redis", var.namespace]
  working_dir = "${var.working_dir}/utils/scripts"
}

# Node names
locals {
  # Redis
  redis_node_ip = try(tomap(data.external.redis_node_ip.result).node_ip, "")

  redis_load_balancer = (kubernetes_service.redis.spec.0.type == "LoadBalancer" ? {
    ip   = (kubernetes_service.redis.status.0.load_balancer.0.ingress.0.ip == "" || kubernetes_service.redis.status.0.load_balancer.0.ingress.0.ip == null ? kubernetes_service.redis.status.0.load_balancer.0.ingress.0.hostname : kubernetes_service.redis.status.0.load_balancer.0.ingress.0.ip)
    port = kubernetes_service.redis.spec.0.port.0.port
    } : {
    ip   = ""
    port = ""
  })

  redis_node_port = (local.redis_load_balancer.ip == "" && kubernetes_service.redis.spec.0.type == "NodePort" ? {
    ip   = local.redis_node_ip
    port = kubernetes_service.redis.spec.0.port.0.node_port
    } : {
    ip   = local.redis_load_balancer.ip
    port = local.redis_load_balancer.port
  })

  redis_endpoints = (local.redis_node_port.ip == "" && kubernetes_service.redis.spec.0.type == "ClusterIP" ? {
    ip   = kubernetes_service.redis.spec.0.cluster_ip
    port = kubernetes_service.redis.spec.0.port.0.port
    } : {
    ip   = local.redis_node_port.ip
    port = local.redis_node_port.port
  })

  redis_url = "${local.redis_endpoints.ip}:${local.redis_endpoints.port}"
}

