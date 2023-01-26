# Seq
module "seq" {
  count         = var.seq != null ? 1 : 0
  source        = "../../../modules/monitoring/seq"
  namespace     = local.namespace
  service_type  = var.seq.service_type
  port          = var.seq.port
  node_selector = var.seq.node_selector
  docker_image = {
    image              = var.seq.image_name
    tag                = try(coalesce(var.seq.image_tag), local.default_tags[var.seq.image_name])
    image_pull_secrets = var.seq.pull_secrets
  }
  working_dir       = "${path.root}/../../.."
  authentication    = var.seq.authentication
  system_ram_target = var.seq.system_ram_target
}

resource "kubernetes_secret" "seq" {
  metadata {
    name      = "seq-endpoints"
    namespace = local.namespace
  }
  data = var.seq != null ? {
    host    = module.seq.0.host
    port    = module.seq.0.port
    url     = module.seq.0.url
    web_url = module.seq.0.web_url
    enabled = true
    } : {
    host    = null
    port    = null
    url     = null
    web_url = null
    enabled = false
  }
}

# node exporter
module "node_exporter" {
  count         = var.node_exporter != null ? 1 : 0
  source        = "../../../modules/monitoring/exporters/node-exporter"
  namespace     = local.namespace
  node_selector = var.node_exporter.node_selector
  docker_image = {
    image              = var.node_exporter.image_name
    tag                = try(coalesce(var.node_exporter.image_tag), local.default_tags[var.node_exporter.image_name])
    image_pull_secrets = var.node_exporter.pull_secrets
  }
  working_dir = "${path.root}/../../../.."
}

# Metrics exporter
module "metrics_exporter" {
  source               = "../../../modules/monitoring/exporters/metrics-exporter"
  namespace            = local.namespace
  service_type         = var.metrics_exporter.service_type
  node_selector        = var.metrics_exporter.node_selector
  storage_endpoint_url = local.storage_endpoint_url
  docker_image = {
    image              = var.metrics_exporter.image_name
    tag                = try(coalesce(var.metrics_exporter.image_tag), local.default_tags[var.metrics_exporter.image_name])
    image_pull_secrets = var.metrics_exporter.pull_secrets
  }
  extra_conf  = var.metrics_exporter.extra_conf
  working_dir = "${path.root}/../../.."
}

resource "kubernetes_secret" "metrics_exporter" {
  metadata {
    name      = "metrics-exporter-endpoints"
    namespace = local.namespace
  }
  data = {
    name      = module.metrics_exporter.name
    host      = module.metrics_exporter.host
    port      = module.metrics_exporter.port
    url       = module.metrics_exporter.url
    namespace = module.metrics_exporter.namespace
  }
}

# Partition metrics exporter
module "partition_metrics_exporter" {
  count                = var.partition_metrics_exporter != null ? 1 : 0
  source               = "../../../modules/monitoring/exporters/partition-metrics-exporter"
  namespace            = local.namespace
  service_type         = var.partition_metrics_exporter.service_type
  node_selector        = var.partition_metrics_exporter.node_selector
  storage_endpoint_url = local.storage_endpoint_url
  metrics_exporter_url = "${module.metrics_exporter.host}:${module.metrics_exporter.port}"
  docker_image = {
    image              = var.partition_metrics_exporter.image_name
    tag                = try(coalesce(var.partition_metrics_exporter.image_tag), local.default_tags[var.partition_metrics_exporter.image_name])
    image_pull_secrets = var.partition_metrics_exporter.pull_secrets
  }
  extra_conf  = var.partition_metrics_exporter.extra_conf
  working_dir = "${path.root}/../../.."
  depends_on  = [module.metrics_exporter]
}

resource "kubernetes_secret" "partition_metrics_exporter" {
  metadata {
    name      = "partition-metrics-exporter-endpoints"
    namespace = local.namespace
  }
  data = var.partition_metrics_exporter != null ? {
    name      = module.partition_metrics_exporter.name
    host      = module.partition_metrics_exporter.host
    port      = module.partition_metrics_exporter.port
    url       = module.partition_metrics_exporter.url
    namespace = module.partition_metrics_exporter.namespace
    } : {
    name      = null
    host      = null
    port      = null
    url       = null
    namespace = null
  }
}

# Prometheus
module "prometheus" {
  source                         = "../../../modules/monitoring/prometheus"
  namespace                      = local.namespace
  service_type                   = var.prometheus.service_type
  node_selector                  = var.prometheus.node_selector
  metrics_exporter_url           = "${module.metrics_exporter.host}:${module.metrics_exporter.port}"
  partition_metrics_exporter_url = length(module.partition_metrics_exporter) == 1 ? "${module.partition_metrics_exporter[0].host}:${module.partition_metrics_exporter[0].port}" : null
  docker_image = {
    image              = var.prometheus.image_name
    tag                = try(coalesce(var.prometheus.image_tag), local.default_tags[var.prometheus.image_name])
    image_pull_secrets = var.prometheus.pull_secrets
  }
  working_dir = "${path.root}/../../.."
}

# Grafana
module "grafana" {
  count          = var.grafana != null ? 1 : 0
  source         = "../../../modules/monitoring/grafana"
  namespace      = local.namespace
  service_type   = var.grafana.service_type
  port           = var.grafana.port
  node_selector  = var.grafana.node_selector
  prometheus_url = module.prometheus.url
  docker_image = {
    image              = var.grafana.image_name
    tag                = try(coalesce(var.grafana.image_tag), local.default_tags[var.grafana.image_name])
    image_pull_secrets = var.grafana.pull_secrets
  }
  working_dir    = "${path.root}/../../.."
  authentication = var.grafana.authentication
}

resource "kubernetes_secret" "grafana" {
  metadata {
    name      = "grafana-endpoints"
    namespace = local.namespace
  }
  data = var.grafana != null ? {
    host    = module.grafana.0.host
    port    = module.grafana.0.port
    url     = module.grafana.0.url
    enabled = true
    } : {
    host    = null
    port    = null
    url     = null
    enabled = false
  }
}

# Fluent-bit
module "fluent_bit" {
  source        = "../../../modules/monitoring/fluent-bit"
  namespace     = local.namespace
  node_selector = var.fluent_bit.node_selector
  fluent_bit = {
    container_name     = "fluent-bit"
    image              = var.fluent_bit.image_name
    tag                = try(coalesce(var.fluent_bit.image_tag), local.default_tags[var.fluent_bit.image_name])
    image_pull_secrets = var.fluent_bit.pull_secrets
    is_daemonset       = var.fluent_bit.is_daemonset
    http_server        = (var.fluent_bit.http_port == 0 ? "Off" : "On")
    http_port          = (var.fluent_bit.http_port == 0 ? "" : tostring(var.fluent_bit.http_port))
    read_from_head     = (var.fluent_bit.read_from_head ? "On" : "Off")
    read_from_tail     = (var.fluent_bit.read_from_head ? "Off" : "On")
  }
  seq = length(module.seq) != 0 ? {
    host    = module.seq[0].host
    port    = module.seq[0].port
    enabled = true
  } : {}
}

resource "kubernetes_secret" "fluent_bit" {
  metadata {
    name      = "fluent-bit-endpoints"
    namespace = local.namespace
  }
  data = {
    is_daemonset = module.fluent_bit.is_daemonset
    name         = module.fluent_bit.container_name
    image        = module.fluent_bit.image
    tag          = module.fluent_bit.tag
    envvars      = module.fluent_bit.configmaps.envvars
    config       = module.fluent_bit.configmaps.config
  }
}

locals {
  monitoring = {
    seq = try({
      host    = module.seq[0].host
      port    = module.seq[0].port
      url     = module.seq[0].url
      web_url = module.seq[0].web_url
      enabled = true
    }, null)
    grafana = try({
      host    = module.grafana[0].host
      port    = module.grafana[0].port
      url     = module.grafana[0].url
      enabled = true
    }, null)
    prometheus = try({
      host = module.prometheus.host
      port = module.prometheus.port
      url  = module.prometheus.url
    }, null)
    metrics_exporter = try({
      name      = module.metrics_exporter.name
      host      = module.metrics_exporter.host
      port      = module.metrics_exporter.port
      url       = module.metrics_exporter.url
      namespace = module.metrics_exporter.namespace
    }, null)
    partition_metrics_exporter = try({
      name      = module.partition_metrics_exporter[0].name
      host      = module.partition_metrics_exporter[0].host
      port      = module.partition_metrics_exporter[0].port
      url       = module.partition_metrics_exporter[0].url
      namespace = module.partition_metrics_exporter[0].namespace
    }, null)
    fluent_bit = try({
      container_name = module.fluent_bit.container_name
      image          = module.fluent_bit.image
      tag            = module.fluent_bit.tag
      is_daemonset   = module.fluent_bit.is_daemonset
      configmaps = {
        envvars = module.fluent_bit.configmaps.envvars
        config  = module.fluent_bit.configmaps.config
      }
    }, null)
  }
}
