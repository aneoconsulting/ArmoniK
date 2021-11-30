# Object storage
output "object_storage" {
  value = kubernetes_service.redis
}

# Table storage
output "table_storage" {
  value = kubernetes_service.mongodb
}

# Queue storage
output "queue_storage" {
  value = kubernetes_service.activemq
}