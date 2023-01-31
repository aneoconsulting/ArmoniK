resource "kubernetes_secret" "shared_storage" {
  metadata {
    name      = "shared-storage-endpoints"
    namespace = var.namespace
  }
  data = {
    host_path         = local.shared_storage_host_path
    file_storage_type = local.shared_storage_file_storage_type
    file_server_ip    = local.shared_storage_file_server_ip
  }
}

resource "kubernetes_secret" "deployed_object_storage" {
  metadata {
    name      = "deployed-object-storage"
    namespace = var.namespace
  }
  data = {
    list = join(",", var.object_storages_to_be_deployed)
  }
}