# Keda
module "keda" {
  source    = "../generated/modules/monitoring/keda"
  namespace = local.keda_namespace
  docker_image = {
    keda = {
      image = local.keda_keda_image
      tag   = local.keda_keda_tag
    }
    metricsApiServer = {
      image = local.keda_metricsApiServer_image
      tag   = local.keda_metricsApiServer_tag
    }
  }
  image_pull_secrets              = local.keda_image_pull_secrets
  node_selector                   = local.keda_node_selector
  metrics_server_dns_policy       = var.keda.metrics_server_dns_policy
  metrics_server_use_host_network = var.keda.metrics_server_use_host_network
  helm_chart_repository           = var.keda.helm_chart_repository
  helm_chart_version              = var.keda.helm_chart_version
}