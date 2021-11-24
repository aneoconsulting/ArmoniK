/*resource "kubernetes_persistent_volume" "nfs_persistent_volume" {
  metadata {
    name = var.nfs_persistent_volume_name
  }
  spec {
    access_modes = [var.access_mode]
    storage_class_name = var.storage_class_name
    volume_mode = var.persistent_volume_mode
    persistent_volume_reclaim_policy = var.persistent_volume_reclaim_policy
    capacity     = {
      storage = var.nfs_persistent_volume_size
    }
    persistent_volume_source {
      local {
        path = var.local_pv_path
      }
    }
    node_affinity {
      required {
        node_selector_term {
          match_expressions {
            key      = "kubernetes.io/hostname"
            operator = "DoesNotExist"
            values = []
          }
        }
      }
    }
  }
}*/