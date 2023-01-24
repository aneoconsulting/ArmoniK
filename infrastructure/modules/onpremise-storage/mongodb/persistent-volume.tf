resource "kubernetes_storage_class" "mongodb" {
  count = (var.persistent_volume != null && var.persistent_volume != "" ? 1 : 0)
  metadata {
    name = "mongodb"
    labels = {
      app     = "mongodb"
      type    = "storage-class"
      service = "persistent-volume"
    }
  }
  mount_options       = ["tls"]
  storage_provisioner = var.persistent_volume.storage_provisioner
  parameters          = var.persistent_volume.parameters
}

resource "kubernetes_persistent_volume_claim" "mongodb" {
  count = length(kubernetes_storage_class.mongodb)
  metadata {
    name      = "mongodb"
    namespace = var.namespace
    labels = {
      app     = "mongodb"
      type    = "persistent-volume-claim"
      service = "persistent-volume"
    }
  }
  spec {
    access_modes       = ["ReadWriteMany"]
    storage_class_name = kubernetes_storage_class.mongodb.0.metadata.0.name
    resources {
      requests = var.persistent_volume.resources.requests
      limits   = var.persistent_volume.resources.limits
    }
  }
}
