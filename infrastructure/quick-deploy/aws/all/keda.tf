# Keda
module "keda" {
  source    = "../../../modules/monitoring/keda"
  namespace = var.keda.namespace
  docker_image = {
    keda             = local.ecr_images["${var.keda.keda_image_name}:${try(coalesce(var.keda.keda_image_tag), "")}"]
    metricsApiServer = local.ecr_images["${var.keda.apiserver_image_name}:${try(coalesce(var.keda.apiserver_image_tag), "")}"]
  }
  image_pull_secrets    = var.keda.pull_secrets
  node_selector         = var.keda.node_selector
  helm_chart_repository = var.keda.helm_chart_repository
  helm_chart_version    = var.keda.helm_chart_version
}
