locals {
  redis_pod_ip = kubernetes_service.redis.status.0.load_balancer.0.ingress.0.ip == "" ? lookup(tomap(data.external.external_ip.result), "external_ip", "localhost") : kubernetes_service.redis.status.0.load_balancer.0.ingress.0.ip
  mongodb_pod_ip = kubernetes_service.mongodb.status.0.load_balancer.0.ingress.0.ip == "" ? lookup(tomap(data.external.external_ip.result), "external_ip", "localhost") : kubernetes_service.mongodb.status.0.load_balancer.0.ingress.0.ip
  local_services_pod_ip = kubernetes_service.local_services.status.0.load_balancer.0.ingress.0.ip == "" ? lookup(tomap(data.external.external_ip.result), "external_ip", "localhost") : kubernetes_service.local_services.status.0.load_balancer.0.ingress.0.ip
}
