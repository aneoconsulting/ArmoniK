# configmap with all the variables
resource "kubernetes_config_map" "worker_config" {
  metadata {
    name      = "worker-configmap"
    namespace = var.namespace
  }
  data = {
    target_grpc_sockets_path   = "/cache"
    target_data_path           = "/data"
    Serilog__MinimumLevel      = var.logging_level
    Grpc__Endpoint             = local.control_plane_url
    S3Storage__ServiceURL      = local.service_url
    S3Storage__AccessKeyId     = local.access_key_id
    S3Storage__SecretAccessKey = local.secret_access_key
    S3Storage__BucketName      = local.name
    FileStorageType            = local.check_file_storage_type
  }
}
