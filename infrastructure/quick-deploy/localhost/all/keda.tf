# Keda
module "keda" {
  source    = "../../../modules/monitoring/keda"
  namespace = var.keda.namespace
  docker_image = {
    keda = {
      image = var.keda.keda_image_name
      tag   = var.keda.keda_image_tag
    }
    metricsApiServer = {
      image = var.keda.apiserver_image_name
      tag   = var.keda.apiserver_image_tag
    }
  }
  image_pull_secrets = var.keda.pull_secrets
  node_selector      = var.keda.node_selector
}
