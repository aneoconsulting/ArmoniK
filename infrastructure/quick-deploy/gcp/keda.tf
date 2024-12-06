# Keda
module "keda" {
  source    = "./generated/infra-modules/monitoring/onpremise/keda"
  namespace = var.keda.namespace
  docker_image = {
    keda             = local.docker_images["${var.keda.image_name}:${try(coalesce(var.keda.image_tag), "")}"]
    metricsApiServer = local.docker_images["${var.keda.apiserver_image_name}:${try(coalesce(var.keda.apiserver_image_tag), "")}"]
  }
  image_pull_secrets              = var.keda.pull_secrets
  node_selector                   = var.keda.node_selector
  helm_chart_repository           = try(coalesce(var.keda.helm_chart_repository), var.helm_charts.keda.repository)
  helm_chart_version              = try(coalesce(var.keda.helm_chart_version), var.helm_charts.keda.version)
  metrics_server_dns_policy       = var.keda.metrics_server_dns_policy
  metrics_server_use_host_network = var.keda.metrics_server_use_host_network
}
