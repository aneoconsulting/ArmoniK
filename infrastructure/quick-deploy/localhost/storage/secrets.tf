resource "kubernetes_secret" "shared_storage" {
  metadata {
    name = "shared-storage-endpoints"
  }
  data = {
    host_path         = local.shared_storage_host_path
    file_storage_type = local.shared_storage_file_storage_type
    file_server_ip    = local.shared_storage_file_server_ip
  }
}