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

# Shared storage
output "shared_storage_claim" {
  value = kubernetes_persistent_volume_claim.nfs_persistent_volume_claim.metadata.0.name
}