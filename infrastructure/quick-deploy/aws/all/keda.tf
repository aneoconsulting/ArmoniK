# Keda
module "keda" {
  source    = "../../../modules/monitoring/keda"
  namespace = var.keda.namespace
  docker_image = {
    keda             = local.ecr_images.keda
    metricsApiServer = local.ecr_images.keda_metrics_apiserver
  }
  image_pull_secrets = var.keda.pull_secrets
  node_selector      = var.keda.node_selector
}
