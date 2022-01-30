# Use Seq
module "seq" {
  source       = "./modules/monitoring/seq"
  count        = (var.monitoring.seq.use ? 1 : 0)
  namespace    = var.monitoring.namespace
  docker_image = {
    image = var.monitoring.seq.image
    tag   = var.monitoring.seq.tag
  }
}

# Use Grafana
module "grafana" {
  source       = "./modules/monitoring/grafana"
  count        = (var.monitoring.grafana.use ? 1 : 0)
  namespace    = var.monitoring.namespace
  docker_image = {
    image = var.monitoring.grafana.image
    tag   = var.monitoring.grafana.tag
  }
}

# Use Prometheus
module "prometheus" {
  source       = "./modules/monitoring/prometheus"
  count        = (var.monitoring.prometheus.use ? 1 : 0)
  namespace    = var.monitoring.namespace
  docker_image = {
    image = var.monitoring.prometheus.image
    tag   = var.monitoring.prometheus.tag
  }
}

locals {
  seq_endpoint_url        = (var.monitoring.seq.use ? module.seq.0.seq_web_url : "")
  grafana_endpoint_url    = (var.monitoring.grafana.use ? module.grafana.0.grafana_url : "")
  prometheus_endpoint_url = (var.monitoring.prometheus.use ? module.prometheus.0.prometheus_url : "")
}