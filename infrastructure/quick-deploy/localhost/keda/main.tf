# Keda
module "keda" {
  source             = "../../../modules/monitoring/keda"
  namespace          = local.keda_namespace
  docker_image       = {
    keda             = {
      image = local.keda_keda_image
      tag   = local.keda_keda_tag
    }
    metricsApiServer = {
      image = local.keda_metricsApiServer_image
      tag   = local.keda_metricsApiServer_tag
    }
  }
  image_pull_secrets = local.keda_image_pull_secrets
  node_selector      = local.keda_node_selector
}