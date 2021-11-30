# Object storage
output "object_storage" {
  value = kubernetes_service.redis
}

# Table storage
output "table_storage" {
  value = kubernetes_service.mongodb
}