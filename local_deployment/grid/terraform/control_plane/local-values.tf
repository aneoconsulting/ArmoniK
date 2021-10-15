locals {
  redis_pod_ip = kubernetes_service.redis.spec.0.cluster_ip
  mongodb_pod_ip = kubernetes_service.mongodb.spec.0.cluster_ip
  queue_pod_ip = kubernetes_service.rsmq.spec.0.cluster_ip
}
