# Keda
module "keda" {
  source    = "../generated/infra-modules/monitoring/onpremise/keda"
  namespace = var.namespace
  docker_image = {
    keda = {
      image = local.image
      tag   = var.keda.docker_image.keda.tag
    }
    metricsApiServer = {
      image = local.metrics_api_server_image
      tag   = var.keda.docker_image.metrics_api_server.tag
    }
  }
  image_pull_secrets              = var.keda.image_pull_secrets
  node_selector                   = var.keda.node_selector
  helm_chart_repository           = var.keda.helm_chart_repository
  helm_chart_version              = var.keda.helm_chart_version
  metrics_server_dns_policy       = var.keda.metrics_server_dns_policy
  metrics_server_use_host_network = var.keda.metrics_server_use_host_network
}