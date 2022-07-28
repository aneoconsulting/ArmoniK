# Metrics server
module "metrics_server" {
  source             = "../../../modules/monitoring/metrics-server"
  namespace          = local.namespace
  docker_image       = {
    image = local.image
    tag   = local.tag
  }
  image_pull_secrets = local.image_pull_secrets
  node_selector      = local.node_selector
}