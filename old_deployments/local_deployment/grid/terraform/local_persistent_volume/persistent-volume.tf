resource "kubernetes_persistent_volume" "nfs_persistent_volume" {
  metadata {
    name   = var.persistent_volume_name
    labels = {
      type = "local"
    }
  }
  spec {
    storage_class_name               = var.storage_class_name
    persistent_volume_reclaim_policy = var.persistent_volume_reclaim_policy
    access_modes                     = [var.access_mode]
    capacity                         = {
      storage = var.persistent_volume_size
    }
    persistent_volume_source {
      host_path {
        path = var.persistent_volume_host_path
      }
    }
  }
}