resource "kubernetes_persistent_volume_claim" "nfs_persistent_volume_claim" {
  metadata {
    name = var.nfs_persistent_volume_claim_name
    namespace = "default"
  }
  spec {
    storage_class_name = var.storage_class_name
    access_modes = [var.access_mode]
    resources {
      requests = {
        storage = var.nfs_persistent_volume_claim_size
      }
    }
    //volume_name = kubernetes_persistent_volume.nfs_persistent_volume.metadata.0.name
  }
}