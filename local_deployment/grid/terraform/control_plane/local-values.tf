locals {
  redis_pod_ip = kubernetes_service.redis.spec.0.cluster_ip
  mongodb_pod_ip = kubernetes_service.mongodb.spec.0.cluster_ip
  queue_pod_ip = kubernetes_service.rsmq.spec.0.cluster_ip
  nginx_pod_ip = kubernetes_service.nginx_ingress_controller_service.spec.0.cluster_ip
  nginx_pod_external_ip = kubernetes_service.nginx_ingress_controller_service.status.0.load_balancer.0.ingress.0.ip
}
