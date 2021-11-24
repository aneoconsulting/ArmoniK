output "local_persistent_volume_claim" {
  value = kubernetes_persistent_volume_claim.nfs_persistent_volume_claim.metadata.0.name
}