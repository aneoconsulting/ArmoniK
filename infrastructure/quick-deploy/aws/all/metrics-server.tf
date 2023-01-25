# Metrics server
module "metrics_server" {
  source             = "../../../modules/monitoring/metrics-server"
  namespace          = var.metrics_server.namespace
  docker_image       = local.ecr_images["${var.metrics_server.image_name}:${try(coalesce(var.metrics_server.image_tag), "")}"]
  image_pull_secrets = var.metrics_server.image_pull_secrets
  node_selector      = var.metrics_server.node_selector
  default_args       = var.metrics_server.args
  host_network       = var.metrics_server.host_network
}
