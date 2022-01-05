# NFS to share files between pods

# Storage class
resource "kubernetes_storage_class" "nfs_storage_class" {
  storage_provisioner = var.nfs.storage_class.provisioner
  metadata {
    name = var.nfs.storage_class.name
  }
  parameters          = {
    server   = var.nfs.server
    path     = var.nfs.path
    readonly = false
  }
}

# Persistent volume
resource "kubernetes_persistent_volume" "nfs_persistent_volume" {
  metadata {
    name = var.nfs.persistent_volume.name
  }
  spec {
    volume_mode                      = "Filesystem"
    access_modes                     = var.nfs.access_modes
    persistent_volume_reclaim_policy = var.nfs.persistent_volume.persistent_volume_reclaim_policy
    storage_class_name               = kubernetes_storage_class.nfs_storage_class.metadata.0.name
    capacity                         = {
      storage = var.nfs.size
    }
    mount_options                    = ["hard", "nfsvers=4.1"]
    persistent_volume_source {
      nfs {
        server    = var.nfs.server
        path      = var.nfs.path
        read_only = false
      }
    }
  }
}

# Persistent volume claim
resource "kubernetes_persistent_volume_claim" "nfs_persistent_volume_claim" {
  metadata {
    name      = var.nfs.persistent_volume_claim.name
    namespace = var.namespace
  }
  spec {
    storage_class_name = kubernetes_storage_class.nfs_storage_class.metadata.0.name
    access_modes       = var.nfs.access_modes
    resources {
      requests = {
        storage = var.nfs.size
      }
    }
  }
}