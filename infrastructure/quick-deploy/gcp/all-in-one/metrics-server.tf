# Metrics server
module "metrics_server" {
  count                 = var.metrics_server != null ? 1 : 0
  source                = "./generated/infra-modules/monitoring/onpremise/metrics-server"
  namespace             = var.metrics_server.namespace
  docker_image          = local.docker_images["${var.metrics_server.image_name}:${try(coalesce(var.metrics_server.image_tag), "")}"]
  image_pull_secrets    = var.metrics_server.image_pull_secrets
  node_selector         = var.metrics_server.node_selector
  default_args          = var.metrics_server.args
  host_network          = var.metrics_server.host_network
  helm_chart_repository = try(coalesce(var.metrics_server.helm_chart_repository), var.helm_charts.metrics_server.repository)
  helm_chart_version    = try(coalesce(var.metrics_server.helm_chart_version), var.helm_charts.metrics_server.version)
}
