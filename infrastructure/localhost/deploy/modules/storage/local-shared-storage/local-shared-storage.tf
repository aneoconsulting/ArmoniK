# In the local deployment:
# Local persistent volume is used to share files between pods

# Storage class
resource "kubernetes_storage_class" "nfs_storage_class" {
  storage_provisioner    = "kubernetes.io/no-provisioner"
  metadata {
    name = var.local_shared_storage.storage_class.name
  }
  volume_binding_mode    = "WaitForFirstConsumer"
  allow_volume_expansion = true
}

# Persistent volume
resource "kubernetes_persistent_volume" "nfs_persistent_volume" {
  metadata {
    name   = var.local_shared_storage.persistent_volume.name
    labels = {
      type = "local"
    }
  }
  spec {
    storage_class_name               = kubernetes_storage_class.nfs_storage_class.metadata.0.name
    persistent_volume_reclaim_policy = "Delete"
    access_modes                     = ["ReadWriteMany"]
    capacity                         = {
      storage = var.local_shared_storage.persistent_volume.size
    }
    persistent_volume_source {
      host_path {
        path = var.local_shared_storage.persistent_volume.host_path
      }
    }
  }
}

# Persistent volume claim
resource "kubernetes_persistent_volume_claim" "nfs_persistent_volume_claim" {
  metadata {
    name      = var.local_shared_storage.persistent_volume_claim.name
    namespace = var.namespace
  }
  spec {
    storage_class_name = kubernetes_storage_class.nfs_storage_class.metadata.0.name
    access_modes       = ["ReadWriteMany"]
    resources {
      requests = {
        storage = var.local_shared_storage.persistent_volume_claim.size
      }
    }
    volume_name        = kubernetes_persistent_volume.nfs_persistent_volume.metadata.0.name
  }
}