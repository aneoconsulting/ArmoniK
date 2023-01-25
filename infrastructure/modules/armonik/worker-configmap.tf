# configmap with all the variables
resource "kubernetes_config_map" "worker_config" {
  metadata {
    name      = "worker-configmap"
    namespace = var.namespace
  }
  data = merge(var.extra_conf.worker, local.file_storage_endpoints, {
    target_data_path = "/data"
    FileStorageType  = local.check_file_storage_type
  })
  depends_on = [kubernetes_service.control_plane]
}
