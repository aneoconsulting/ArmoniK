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
output "shared_storage_class_storage" {
  value = kubernetes_storage_class.nfs_storage_class
}

output "shared_storage_persistent_volume" {
  value = kubernetes_persistent_volume.nfs_persistent_volume
}

output "shared_storage_persistent_volume_claim" {
  value = kubernetes_persistent_volume_claim.nfs_persistent_volume_claim
}