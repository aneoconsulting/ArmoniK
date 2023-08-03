resource "kubernetes_secret" "metrics_exporter" {
  metadata {
    name      = "metrics-exporter"
    namespace = var.namespace
  }
  data = {
    name      = module.metrics_exporter.name
    host      = module.metrics_exporter.host
    port      = module.metrics_exporter.port
    url       = module.metrics_exporter.url
    namespace = module.metrics_exporter.namespace
  }
}

resource "kubernetes_secret" "partition_metrics_exporter" {
  metadata {
    name      = "partition-metrics-exporter"
    namespace = var.namespace
  }
  data = {
    name      = null #module.partition_metrics_exporter.name
    host      = null #module.partition_metrics_exporter.host
    port      = null #module.partition_metrics_exporter.port
    url       = null #module.partition_metrics_exporter.url
    namespace = null #module.partition_metrics_exporter.namespace
  }
}

resource "kubernetes_secret" "fluent_bit" {
  metadata {
    name      = "fluent-bit"
    namespace = var.namespace
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

resource "kubernetes_secret" "prometheus" {
  metadata {
    name      = "prometheus"
    namespace = var.namespace
  }
  data = {
    host = module.prometheus.host
    port = module.prometheus.port
    url  = module.prometheus.url
  }
}

resource "kubernetes_secret" "seq" {
  metadata {
    name      = "seq"
    namespace = var.namespace
  }
  data = local.seq_enabled ? {
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

resource "kubernetes_secret" "grafana" {
  metadata {
    name      = "grafana"
    namespace = var.namespace
  }
  data = local.grafana_enabled ? {
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