# Keda
module "keda" {
  source    = "./generated/infra-modules/monitoring/onpremise/keda"
  namespace = var.keda.namespace
  docker_image = {
    keda = {
      image = var.keda.keda_image_name
      tag   = try(coalesce(var.keda.keda_image_tag), local.default_tags[var.keda.keda_image_name])
    }
    metricsApiServer = {
      image = var.keda.apiserver_image_name
      tag   = try(coalesce(var.keda.apiserver_image_tag), local.default_tags[var.keda.apiserver_image_name])
    }
  }
  image_pull_secrets              = var.keda.pull_secrets
  node_selector                   = var.keda.node_selector
  helm_chart_repository           = try(coalesce(var.keda.helm_chart_repository), var.helm_charts.keda.repository)
  helm_chart_version              = try(coalesce(var.keda.helm_chart_verison), var.helm_charts.keda.version)
  metrics_server_dns_policy       = var.keda.metrics_server_dns_policy
  metrics_server_use_host_network = var.keda.metrics_server_use_host_network
}
