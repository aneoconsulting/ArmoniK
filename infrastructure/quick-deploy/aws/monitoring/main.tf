# Seq
module "seq" {
  count         = (var.monitoring.seq.use ? 1 : 0)
  source        = "../../../modules/monitoring/seq"
  namespace     = var.namespace
  service_type  = var.monitoring.seq.service_type
  node_selector = var.node_selector
  docker_image  = {
    image = var.monitoring.seq.image
    tag   = var.monitoring.seq.tag
  }
  working_dir   = "${path.root}/../../.."
}

# Grafana
module "grafana" {
  count         = (var.monitoring.grafana.use ? 1 : 0)
  source        = "../../../modules/monitoring/grafana"
  namespace     = var.namespace
  service_type  = var.monitoring.grafana.service_type
  node_selector = var.node_selector
  docker_image  = {
    image = var.monitoring.grafana.image
    tag   = var.monitoring.grafana.tag
  }
  working_dir   = "${path.root}/../../.."
}

# Prometheus
module "prometheus" {
  count         = (var.monitoring.prometheus.use ? 1 : 0)
  source        = "../../../modules/monitoring/prometheus"
  namespace     = var.namespace
  service_type  = var.monitoring.prometheus.service_type
  node_selector = var.node_selector
  docker_image  = {
    image = var.monitoring.prometheus.image
    tag   = var.monitoring.prometheus.tag
  }
  working_dir   = "${path.root}/../../.."
}