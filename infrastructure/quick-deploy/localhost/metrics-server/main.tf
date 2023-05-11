# Metrics server
module "metrics_server" {
  source    = "../generated/infra-modules/monitoring/metrics-server"
  namespace = local.namespace
  docker_image = {
    image = local.image
    tag   = local.tag
  }
  image_pull_secrets    = local.image_pull_secrets
  node_selector         = local.node_selector
  default_args          = local.default_args
  host_network          = local.host_network
  helm_chart_repository = var.helm_chart_repository
  helm_chart_version    = var.helm_chart_version
}