locals {
  redis_pod_ip = kubernetes_service.redis.status.0.load_balancer.0.ingress.0.ip == "" ? lookup(tomap(data.external.external_ip.result), "external_ip", "localhost") : kubernetes_service.redis.status.0.load_balancer.0.ingress.0.ip
  redis_without_ssl_pod_ip = kubernetes_service.redis-without-ssl.status.0.load_balancer.0.ingress.0.ip == "" ? lookup(tomap(data.external.external_ip.result), "external_ip", "localhost") : kubernetes_service.redis-without-ssl.status.0.load_balancer.0.ingress.0.ip
  dynamodb_pod_ip = kubernetes_service.dynamodb.status.0.load_balancer.0.ingress.0.ip == "" ? lookup(tomap(data.external.external_ip.result), "external_ip", "localhost") : kubernetes_service.dynamodb.status.0.load_balancer.0.ingress.0.ip
  mongodb_pod_ip = kubernetes_service.mongodb.status.0.load_balancer.0.ingress.0.ip == "" ? lookup(tomap(data.external.external_ip.result), "external_ip", "localhost") : kubernetes_service.mongodb.status.0.load_balancer.0.ingress.0.ip
  local_services_pod_ip = kubernetes_service.local_services.status.0.load_balancer.0.ingress.0.ip == "" ? lookup(tomap(data.external.external_ip.result), "external_ip", "localhost") : kubernetes_service.local_services.status.0.load_balancer.0.ingress.0.ip
  dynamodb_table_id = aws_dynamodb_table.htc_tasks_status_table.id
}
