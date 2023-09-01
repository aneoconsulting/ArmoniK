# Metrics server
module "metrics_server" {
  source    = "../generated/infra-modules/monitoring/onpremise/metrics-server"
  namespace = var.namespace
  docker_image = {
    image = var.metrics_server.image_name
    tag   = try(var.image_tags[var.metrics_server.image_name], var.metrics_server.image_tag)
  }
  image_pull_secrets    = var.metrics_server.image_pull_secrets
  node_selector         = var.metrics_server.node_selector
  default_args          = var.metrics_server.args
  host_network          = var.metrics_server.host_network
  helm_chart_repository = try(var.helm_charts.metrics_server.repository, var.metrics_server.helm_chart_repository)
  helm_chart_version    = try(var.helm_charts.metrics_server.version, var.metrics_server.helm_chart_version)
}