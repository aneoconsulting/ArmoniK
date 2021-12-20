resource "kubernetes_storage_class" "nfs_storage_class" {
  storage_provisioner    = var.storage_provisioner
  metadata {
    name = var.storage_class_name
  }
  volume_binding_mode    = var.volume_binding_mode
  allow_volume_expansion = var.allow_volume_expansion
}