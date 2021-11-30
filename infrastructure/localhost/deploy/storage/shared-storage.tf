# In the local deployment:
# Local persistent volume is used to share files between pods

# Storage class
resource "kubernetes_storage_class" "nfs_storage_class" {
  storage_provisioner    = var.shared_storage.storage_class.provisioner
  metadata {
    name = var.shared_storage.storage_class.name
  }
  volume_binding_mode    = var.shared_storage.storage_class.volume_binding_mode
  allow_volume_expansion = var.shared_storage.storage_class.allow_volume_expansion
}

# Persistent volume
resource "kubernetes_persistent_volume" "nfs_persistent_volume" {
  metadata {
    name   = var.shared_storage.persistent_volume.name
    labels = {
      type = "local"
    }
  }
  spec {
    storage_class_name               = kubernetes_storage_class.nfs_storage_class.metadata.0.name
    persistent_volume_reclaim_policy = var.shared_storage.persistent_volume.persistent_volume_reclaim_policy
    access_modes                     = var.shared_storage.persistent_volume.access_modes
    capacity                         = {
      storage = var.shared_storage.persistent_volume.size
    }
    persistent_volume_source {
      host_path {
        path = var.shared_storage.persistent_volume.path
      }
    }
  }
}

# Persistent volume claim
resource "kubernetes_persistent_volume_claim" "nfs_persistent_volume_claim" {
  metadata {
    name      = var.shared_storage.persistent_volume_claim.name
    namespace = var.namespace
  }
  spec {
    storage_class_name = kubernetes_storage_class.nfs_storage_class.metadata.0.name
    access_modes       = var.shared_storage.persistent_volume_claim.access_modes
    resources {
      requests = {
        storage = var.shared_storage.persistent_volume_claim.size
      }
    }
    volume_name        = kubernetes_persistent_volume.nfs_persistent_volume.metadata.0.name
  }
}