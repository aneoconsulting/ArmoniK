# Object storage
# Redis
output "storage" {
  value = kubernetes_service.redis
}