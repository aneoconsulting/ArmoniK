# Seq
module "seq" {
  count         = (local.seq_use ? 1 : 0)
  source        = "../../../modules/monitoring/seq"
  namespace     = var.namespace
  service_type  = local.seq_service_type
  node_selector = var.node_selector
  docker_image  = {
    image = local.seq_image
    tag   = local.seq_tag
  }
  working_dir   = "${path.root}/../../.."
}

# Grafana
module "grafana" {
  count         = (local.grafana_use ? 1 : 0)
  source        = "../../../modules/monitoring/grafana"
  namespace     = var.namespace
  service_type  = local.grafana_service_type
  node_selector = var.node_selector
  docker_image  = {
    image = local.grafana_image
    tag   = local.grafana_tag
  }
  working_dir   = "${path.root}/../../.."
}

# Prometheus
module "prometheus" {
  count         = (local.prometheus_use ? 1 : 0)
  source        = "../../../modules/monitoring/prometheus"
  namespace     = var.namespace
  service_type  = local.prometheus_service_type
  node_selector = var.node_selector
  docker_image  = {
    prometheus    = {
      image = local.prometheus_image
      tag   = local.prometheus_tag
    }
    node_exporter = {
      image = local.prometheus_node_exporter_image
      tag   = local.prometheus_node_exporter_tag
    }
  }
  working_dir   = "${path.root}/../../.."
}

# Fluent-bit
module "fluent_bit" {
  source        = "../../../modules/monitoring/fluent-bit"
  namespace     = var.namespace
  node_selector = var.node_selector
  seq           = (local.seq_use ? {
    host = module.seq.0.host
    port = module.seq.0.port
    use  = true
  } : {})
  fluent_bit    = {
    container_name = "fluent-bit"
    image          = local.fluent_bit_image
    tag            = local.fluent_bit_tag
    is_daemonset   = local.fluent_bit_is_daemonset
    http_server    = (local.fluent_bit_http_port == 0 ? "Off" : "On")
    http_port      = (local.fluent_bit_http_port == 0 ? "" : tostring(local.fluent_bit_http_port))
    read_from_head = (local.fluent_bit_read_from_head ? "On" : "Off")
    read_from_tail = (local.fluent_bit_read_from_head ? "Off" : "On")
  }
}