# Keda
module "keda" {
  source    = "../generated/infra-modules/monitoring/onpremise/keda"
  namespace = var.namespace
  docker_image = {
    keda = {
      image = var.keda.image_name
      tag   = try(var.image_tags[var.keda.image_name], var.keda.image_tag)
    }
    metricsApiServer = {
      image = var.keda.apiserver_image_name
      tag   = try(var.image_tags[var.keda.apiserver_image_name], var.keda.apiserver_image_tag)
    }
  }
  image_pull_secrets              = var.keda.image_pull_secrets
  node_selector                   = var.keda.node_selector
  metrics_server_dns_policy       = var.keda.metrics_server_dns_policy
  metrics_server_use_host_network = var.keda.metrics_server_use_host_network
  helm_chart_repository           = try(var.helm_charts.keda.repository, var.keda.helm_chart_repository)
  helm_chart_version              = try(var.helm_charts.keda.version, var.keda.helm_chart_version)
}