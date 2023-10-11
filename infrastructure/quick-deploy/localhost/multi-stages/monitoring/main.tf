# Seq
module "seq" {
  count         = (var.monitoring.seq.enabled ? 1 : 0)
  source        = "../generated/infra-modules/monitoring/onpremise/seq"
  namespace     = var.namespace
  service_type  = var.monitoring.seq.service_type
  port          = var.monitoring.seq.port
  node_selector = var.monitoring.seq.node_selector
  docker_image = {
    image              = var.monitoring.seq.image_name
    tag                = try(var.image_tags[var.monitoring.seq.image_name], var.monitoring.seq.image_tag)
    image_pull_secrets = var.monitoring.seq.image_pull_secrets
  }
  docker_image_cron = {
    image              = var.monitoring.seq.cli_image_name
    tag                = try(var.image_tags[var.monitoring.seq.cli_image_name], var.monitoring.seq.cli_image_tag)
    image_pull_secrets = var.monitoring.seq.cli_image_pull_secrets
  }
  authentication    = var.authentication
  system_ram_target = var.monitoring.seq.system_ram_target
  retention_in_days = var.monitoring.seq.retention_in_days
}

# node exporter
module "node_exporter" {
  count         = (var.monitoring.node_exporter.enabled ? 1 : 0)
  source        = "../generated/infra-modules/monitoring/onpremise/exporters/node-exporter"
  namespace     = var.namespace
  node_selector = var.monitoring.node_exporter.node_selector
  docker_image = {
    image              = var.monitoring.node_exporter.image_name
    tag                = try(var.image_tags[var.monitoring.node_exporter.image_name], var.monitoring.node_exporter.image_tag)
    image_pull_secrets = var.monitoring.node_exporter.image_pull_secrets
  }
}

# Metrics exporter
module "metrics_exporter" {
  source        = "../generated/infra-modules/monitoring/onpremise/exporters/metrics-exporter"
  namespace     = var.namespace
  node_selector = var.monitoring.metrics_exporter.node_selector
  service_type  = var.monitoring.metrics_exporter.service_type
  docker_image = {
    image              = var.monitoring.metrics_exporter.image_name
    tag                = try(local.default_tags[var.monitoring.metrics_exporter.image_name], var.monitoring.metrics_exporter.image_tag)
    image_pull_secrets = var.monitoring.metrics_exporter.image_pull_secrets
  }
  extra_conf = var.monitoring.metrics_exporter.extra_conf
}

# Partition metrics exporter
#module "partition_metrics_exporter" {
#  namespace     = var.namespace
#  node_selector = var.monitoring.partition_metrics_exporter.node_selector
#  service_type = var.monitoring.partition_metrics_exporter.service_type
#  docker_image = {
#    image              = var.monitoring.partition_metrics_exporter.image_name
#    tag                = try(local.default_tags[var.monitoring.partition_metrics_exporter.image_name],var.monitoring.partition_metrics_exporter.image_tag)
#    image_pull_secrets = var.monitoring.partition_metrics_exporter.image_pull_secrets
#  }
#  extra_conf = var.monitoring.partition_metrics_exporter.extra_conf
#  depends_on  = [module.partition_metrics_exporter]
#}

# Prometheus
module "prometheus" {
  source               = "../generated/infra-modules/monitoring/onpremise/prometheus"
  namespace            = var.namespace
  service_type         = var.monitoring.prometheus.service_type
  node_selector        = var.monitoring.prometheus.node_selector
  metrics_exporter_url = "${module.metrics_exporter.host}:${module.metrics_exporter.port}"
  #"${module.partition_metrics_exporter.host}:${module.partition_metrics_exporter.port}"
  docker_image = {
    image              = var.monitoring.prometheus.image_name
    tag                = try(var.image_tags[var.monitoring.prometheus.image_name], var.monitoring.prometheus.image_tag)
    image_pull_secrets = var.monitoring.prometheus.image_pull_secrets
  }
  depends_on = [
    module.metrics_exporter,
    #module.partition_metrics_exporter
  ]
}

# Grafana
module "grafana" {
  count          = (var.monitoring.grafana.enabled ? 1 : 0)
  source         = "../generated/infra-modules/monitoring/onpremise/grafana"
  namespace      = var.namespace
  service_type   = var.monitoring.grafana.service_type
  port           = var.monitoring.grafana.port
  node_selector  = var.monitoring.grafana.node_selector
  prometheus_url = module.prometheus.url
  docker_image = {
    image              = var.monitoring.grafana.image_name
    tag                = try(var.image_tags[var.monitoring.grafana.image_name], var.monitoring.grafana.image_tag)
    image_pull_secrets = var.monitoring.grafana.image_pull_secrets
  }
  authentication = var.authentication
  depends_on     = [module.prometheus]
}

# Fluent-bit
module "fluent_bit" {
  source        = "../generated/infra-modules/monitoring/onpremise/fluent-bit"
  namespace     = var.namespace
  node_selector = var.monitoring.fluent_bit.node_selector
  seq = (var.monitoring.seq.enabled ? {
    host    = module.seq.0.host
    port    = module.seq.0.port
    enabled = true
  } : {})
  fluent_bit = {
    container_name                  = "fluent-bit"
    image                           = var.monitoring.fluent_bit.image_name
    tag                             = try(var.image_tags[var.monitoring.fluent_bit.image_name], var.monitoring.fluent_bit.image_tag)
    image_pull_secrets              = var.monitoring.fluent_bit.image_pull_secrets
    is_daemonset                    = var.monitoring.fluent_bit.is_daemonset
    parser                          = var.monitoring.fluent_bit.parser
    http_server                     = (var.monitoring.fluent_bit.http_port == 0 ? "Off" : "On")
    http_port                       = (var.monitoring.fluent_bit.http_port == 0 ? "" : tostring(var.monitoring.fluent_bit.http_port))
    read_from_head                  = (var.monitoring.fluent_bit.read_from_head ? "On" : "Off")
    read_from_tail                  = (var.monitoring.fluent_bit.read_from_head ? "Off" : "On")
    fluentbitstate_hostpath         = optional(string, "/var/fluent-bit/state")
    varlibdockercontainers_hostpath = optional(string, "/var/lib/docker/containers")
    runlogjournal_hostpath          = optional(string, "/run/log/journal")
  }
}
