# Seq
module "seq" {
  count         = (local.seq_enabled ? 1 : 0)
  source        = "../generated/modules/monitoring/seq"
  namespace     = var.namespace
  service_type  = local.seq_service_type
  port          = local.seq_port
  node_selector = local.seq_node_selector
  docker_image = {
    image              = local.seq_image
    tag                = local.seq_tag
    image_pull_secrets = local.seq_image_pull_secrets
  }
  docker_image_cron = {
    image              = local.cli_seq_image
    tag                = local.cli_seq_tag
    image_pull_secrets = local.cli_seq_image_pull_secrets
  }
  working_dir       = "${path.root}/../../.."
  authentication    = var.authentication
  system_ram_target = local.seq_system_ram_target
  retention_in_days = local.retention_in_days
}

# node exporter
module "node_exporter" {
  count         = (local.node_exporter_enabled ? 1 : 0)
  source        = "../generated/modules/monitoring/exporters/node-exporter"
  namespace     = var.namespace
  node_selector = local.node_exporter_node_selector
  docker_image = {
    image              = local.node_exporter_image
    tag                = local.node_exporter_tag
    image_pull_secrets = local.node_exporter_image_pull_secrets
  }
  working_dir = "${path.root}/../../../.."
}

# Metrics exporter
module "metrics_exporter" {
  source               = "../generated/modules/monitoring/exporters/metrics-exporter"
  namespace            = var.namespace
  service_type         = local.metrics_exporter_service_type
  node_selector        = local.metrics_exporter_node_selector
  storage_endpoint_url = var.storage_endpoint_url
  docker_image = {
    image              = local.metrics_exporter_image
    tag                = local.metrics_exporter_tag
    image_pull_secrets = local.metrics_exporter_image_pull_secrets
  }
  extra_conf  = local.metrics_exporter_extra_conf
  working_dir = "${path.root}/../../.."
}

# Partition metrics exporter
#module "partition_metrics_exporter" {
#  source               = "../generated/modules/monitoring/exporters/partition-metrics-exporter"
#  namespace            = var.namespace
#  service_type         = local.partition_metrics_exporter_service_type
#  node_selector        = local.partition_metrics_exporter_node_selector
#  logging_level        = var.logging_level
#  storage_endpoint_url = var.storage_endpoint_url
#  metrics_exporter_url = "${module.metrics_exporter.host}:${module.metrics_exporter.port}"
#  docker_image = {
#    image              = local.partition_metrics_exporter_image
#    tag                = local.partition_metrics_exporter_tag
#    image_pull_secrets = local.partition_metrics_exporter_image_pull_secrets
#  }
#  extra_conf  = local.partition_metrics_exporter_extra_conf
#  working_dir = "${path.root}/../../.."
#  depends_on  = [module.metrics_exporter]
#}

# Prometheus
module "prometheus" {
  source                         = "../generated/modules/monitoring/prometheus"
  namespace                      = var.namespace
  service_type                   = local.prometheus_service_type
  node_selector                  = local.prometheus_node_selector
  metrics_exporter_url           = "${module.metrics_exporter.host}:${module.metrics_exporter.port}"
  partition_metrics_exporter_url = null
  #"${module.partition_metrics_exporter.host}:${module.partition_metrics_exporter.port}"
  docker_image = {
    image              = local.prometheus_image
    tag                = local.prometheus_tag
    image_pull_secrets = local.prometheus_image_pull_secrets
  }
  working_dir = "${path.root}/../../.."
  depends_on = [
    module.metrics_exporter,
    #module.partition_metrics_exporter
  ]
}

# Grafana
module "grafana" {
  count          = (local.grafana_enabled ? 1 : 0)
  source         = "../generated/modules/monitoring/grafana"
  namespace      = var.namespace
  service_type   = local.grafana_service_type
  port           = local.grafana_port
  node_selector  = local.grafana_node_selector
  prometheus_url = module.prometheus.url
  docker_image = {
    image              = local.grafana_image
    tag                = local.grafana_tag
    image_pull_secrets = local.grafana_image_pull_secrets
  }
  working_dir    = "${path.root}/../../.."
  authentication = var.authentication
  depends_on     = [module.prometheus]
}

# Fluent-bit
module "fluent_bit" {
  source        = "../generated/modules/monitoring/fluent-bit"
  namespace     = var.namespace
  node_selector = local.fluent_bit_node_selector
  seq = (local.seq_enabled ? {
    host    = module.seq.0.host
    port    = module.seq.0.port
    enabled = true
  } : {})
  fluent_bit = {
    container_name     = "fluent-bit"
    image              = local.fluent_bit_image
    tag                = local.fluent_bit_tag
    image_pull_secrets = local.fluent_bit_image_pull_secrets
    is_daemonset       = local.fluent_bit_is_daemonset
    parser             = local.fluent_bit_parser
    http_server        = (local.fluent_bit_http_port == 0 ? "Off" : "On")
    http_port          = (local.fluent_bit_http_port == 0 ? "" : tostring(local.fluent_bit_http_port))
    read_from_head     = (local.fluent_bit_read_from_head ? "On" : "Off")
    read_from_tail     = (local.fluent_bit_read_from_head ? "Off" : "On")
  }
}
