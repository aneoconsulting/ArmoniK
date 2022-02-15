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
    S3Storage__ServiceURL      = "https://s3.${var.region}.amazonaws.com"
    S3Storage__AccessKeyId     = ""
    S3Storage__SecretAccessKey = ""
    S3Storage__BucketName      = var.storage_endpoint_url.shared.name
    FileStorageType            = "S3"
  }
}
