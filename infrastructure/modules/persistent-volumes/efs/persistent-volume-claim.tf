resource "kubernetes_persistent_volume_claim" "efs_pvc" {
  metadata {
    name      = "efs-pvc"
    namespace = var.pvc.namespace
    labels = {
      app     = "persistent-volume"
      type    = "persistent-volume-claim"
      service = "efs"
    }
  }
  spec {
    access_modes       = ["ReadWriteMany"]
    storage_class_name = kubernetes_storage_class.efs_storage_class.metadata.0.name
    resources {
      requests = var.pvc.resources.requests
      limits   = var.pvc.resources.limits
    }
  }
}

