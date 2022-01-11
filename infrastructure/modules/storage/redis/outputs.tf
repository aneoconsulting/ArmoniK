# Redis
output "service" {
  value = kubernetes_service.redis
}

output "deployment" {
  value = kubernetes_deployment.redis
}