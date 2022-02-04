# configmap with all the variables
resource "kubernetes_config_map" "worker_config" {
  metadata {
    name      = "worker-configmap"
    namespace = var.namespace
  }
  data = {
    target_grpc_sockets_path = "/cache"
    target_data_path         = "/data"
    Serilog__MinimumLevel    = "${var.logging_level}"
    Redis__EndpointUrl       = "${var.storage_endpoint_url.external.url}"
    Redis__CredentialsPath   = "/redis/redis_credentials"
    Redis__Timeout           = "3000"
    Grpc__Endpoint           = "${local.control_plane_url}"
  }
}