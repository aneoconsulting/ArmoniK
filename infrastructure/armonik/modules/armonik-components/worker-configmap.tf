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
    Grpc__Endpoint           = "${local.control_plane_url}"
  }
}