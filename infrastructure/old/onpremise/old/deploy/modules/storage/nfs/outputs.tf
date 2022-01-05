# NFS storage
output "nfs_storage_class_storage" {
  value = kubernetes_storage_class.nfs_storage_class
}

output "nfs_storage_persistent_volume" {
  value = kubernetes_persistent_volume.nfs_persistent_volume
}

output "nfs_storage_persistent_volume_claim" {
  value = kubernetes_persistent_volume_claim.nfs_persistent_volume_claim
}