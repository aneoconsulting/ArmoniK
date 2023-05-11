# Keda
module "keda" {
  source    = "../generated/infra-modules/monitoring/keda"
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
  helm_chart_repository           = local.keda_chart_repository
  helm_chart_version              = local.keda_chart_version
  metrics_server_dns_policy       = local.keda_metrics_server_dns_policy
  metrics_server_use_host_network = local.keda_metrics_server_use_host_network
}