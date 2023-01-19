# Keda
module "keda" {
  source    = "../../../modules/monitoring/keda"
  namespace = var.keda.namespace
  docker_image = {
    keda             = local.ecr_images["${var.keda.keda_image_name}:${var.keda.keda_image_tag}"]
    metricsApiServer = local.ecr_images["${var.keda.apiserver_image_name}:${var.keda.apiserver_image_tag}"]
  }
  image_pull_secrets = var.keda.pull_secrets
  node_selector      = var.keda.node_selector
}
