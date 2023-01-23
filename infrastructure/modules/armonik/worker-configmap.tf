# configmap with all the variables
resource "kubernetes_config_map" "worker_config" {
  metadata {
    name      = "worker-configmap"
    namespace = var.namespace
  }
  data = merge(var.extra_conf.worker, {
    target_data_path           = "/data"
    S3Storage__ServiceURL      = local.service_url
    S3Storage__AccessKeyId     = local.access_key_id
    S3Storage__SecretAccessKey = local.secret_access_key
    S3Storage__BucketName      = local.name
    FileStorageType            = local.check_file_storage_type
  })
  depends_on = [kubernetes_service.control_plane]
}
