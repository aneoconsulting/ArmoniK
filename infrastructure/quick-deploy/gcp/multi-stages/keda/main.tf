data "google_client_config" "current" {}

# Keda
module "keda" {
  source    = "../generated/infra-modules/monitoring/onpremise/keda"
  namespace = var.namespace
  docker_image = {
    keda = {
      image = var.gar.repositories["${var.keda.image_name}:${var.keda.image_tag}"]
      tag   = var.keda.image_tag
    }
    metricsApiServer = {
      image = var.gar.repositories["${var.keda.apiserver_image_name}:${var.keda.apiserver_image_tag}"]
      tag   = var.keda.apiserver_image_tag
    }
  }
  image_pull_secrets              = var.keda.pull_secrets
  node_selector                   = var.keda.node_selector
  helm_chart_repository           = var.keda.helm_chart_repository
  helm_chart_version              = var.keda.helm_chart_version
  metrics_server_dns_policy       = var.keda.metrics_server_dns_policy
  metrics_server_use_host_network = var.keda.metrics_server_use_host_network
}