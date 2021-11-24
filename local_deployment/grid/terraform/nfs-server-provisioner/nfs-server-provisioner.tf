resource "helm_release" "nfs_server_provisioner" {
  name  = "nfs-server-provisioner"
  chart = "nfs-server-provisioner"
  namespace  = "default"
  repository = var.nfs_server_provisioner_chart_url

  set {
    name  = "replicaCount"
    value = var.replica_count
  }

  set {
    name  = "persistence.enabled"
    value = var.persistence
  }

  set {
    name  = "persistence.storageClass"
    value = var.storage_class_name
  }

  set {
    name  = "persistence.accessMode"
    value = var.access_mode
  }

  set {
    name  = "persistence.size"
    value = var.volume_size
  }

  set {
    name  = "storageClass.create"
    value = var.create_storage_class
  }

  set {
    name  = "storageClass.defaultClass"
    value = var.default_class
  }

  set {
    name  = "storageClass.defaultClass"
    value = var.default_class
  }

  set {
    name  = "storageClass.name"
    value = var.storage_class_name
  }
}