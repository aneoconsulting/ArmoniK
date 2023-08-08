# Metrics server
module "metrics_server" {
  source    = "../generated/infra-modules/monitoring/onpremise/metrics-server"
  namespace = var.namespace
  docker_image = {
    image = local.image
    tag   = var.docker_image.tag
  }
  image_pull_secrets    = var.image_pull_secrets
  node_selector         = var.node_selector
  default_args          = local.default_args
  host_network          = var.host_network
  helm_chart_repository = var.helm_chart_repository
  helm_chart_version    = var.helm_chart_version
}