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
    Grpc__Endpoint             = "http://${kubernetes_service.control_plane.spec.0.cluster_ip}:${kubernetes_service.control_plane.spec.0.port.0.port}"
    S3Storage__ServiceURL      = local.service_url
    S3Storage__AccessKeyId     = local.access_key_id
    S3Storage__SecretAccessKey = local.secret_access_key
    S3Storage__BucketName      = local.name
    FileStorageType            = local.check_file_storage_type
  }
  depends_on = [kubernetes_service.control_plane]
}
