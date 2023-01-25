# Keda
module "keda" {
  source    = "../../../modules/monitoring/keda"
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
  image_pull_secrets = var.keda.pull_secrets
  node_selector      = var.keda.node_selector
}
