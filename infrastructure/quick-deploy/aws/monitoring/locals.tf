data "aws_caller_identity" "current" {}

resource "random_string" "random_resources" {
  length  = 5
  special = false
  upper   = false
  number  = true
}

locals {
  random_string             = random_string.random_resources.result
  suffix                    = var.suffix != null && var.suffix != "" ? var.suffix : local.random_string
  cluster_name              = lookup(var.eks, "name", "")
  kms_name                  = "armonik-kms-cloudwatch-${local.suffix}-${local.random_string}"
  cloudwatch_log_group_name = "/aws/containerinsights/${local.cluster_name}/application"
  tags                      = merge(var.tags, {
    application        = "ArmoniK"
    deployment_version = local.suffix
    created_by         = data.aws_caller_identity.current.arn
    date               = formatdate("EEE-DD-MMM-YY-hh:mm:ss:ZZZ", tostring(timestamp()))
    resource           = "monitoring"
  })

  # Seq
  seq_enabled            = tobool(lookup(lookup(var.monitoring, "seq", {}), "enabled", false))
  seq_image              = lookup(lookup(var.monitoring, "seq", {}), "image", "${data.aws_caller_identity.current.id}.dkr.ecr.eu-west-3.amazonaws.com/seq")
  seq_tag                = lookup(lookup(var.monitoring, "seq", {}), "tag", "2021.4")
  seq_image_pull_secrets = lookup(lookup(var.monitoring, "seq", {}), "image_pull_secrets", "")
  seq_service_type       = lookup(lookup(var.monitoring, "seq", {}), "service_type", "LoadBalancer")
  seq_node_selector      = lookup(lookup(var.monitoring, "seq", {}), "node_selector", {})

  # Grafana
  grafana_enabled            = tobool(lookup(lookup(var.monitoring, "grafana", {}), "enabled", false))
  grafana_image              = lookup(lookup(var.monitoring, "grafana", {}), "image", "${data.aws_caller_identity.current.id}.dkr.ecr.eu-west-3.amazonaws.com/grafana")
  grafana_tag                = lookup(lookup(var.monitoring, "grafana", {}), "tag", "latest")
  grafana_image_pull_secrets = lookup(lookup(var.monitoring, "grafana", {}), "image_pull_secrets", "")
  grafana_service_type       = lookup(lookup(var.monitoring, "grafana", {}), "service_type", "LoadBalancer")
  grafana_node_selector      = lookup(lookup(var.monitoring, "grafana", {}), "node_selector", {})

  # node exporter
  node_exporter_enabled            = tobool(lookup(lookup(var.monitoring, "node_exporter", {}), "enabled", false))
  node_exporter_image              = lookup(lookup(var.monitoring, "node_exporter", {}), "image", "${data.aws_caller_identity.current.id}.dkr.ecr.eu-west-3.amazonaws.com/node-exporter")
  node_exporter_tag                = lookup(lookup(var.monitoring, "node_exporter", {}), "tag", "latest")
  node_exporter_image_pull_secrets = lookup(lookup(var.monitoring, "node_exporter", {}), "image_pull_secrets", "")
  node_exporter_node_selector      = lookup(lookup(var.monitoring, "node_exporter", {}), "node_selector", {})

  # Prometheus
  prometheus_image               = lookup(lookup(var.monitoring, "prometheus", {}), "image", "${data.aws_caller_identity.current.id}.dkr.ecr.eu-west-3.amazonaws.com/prometheus")
  prometheus_tag                 = lookup(lookup(var.monitoring, "prometheus", {}), "tag", "latest")
  prometheus_image_pull_secrets  = lookup(lookup(var.monitoring, "prometheus", {}), "image_pull_secrets", "")
  prometheus_service_type        = lookup(lookup(var.monitoring, "prometheus", {}), "service_type", "ClusterIP")
  prometheus_node_exporter_image = lookup(lookup(lookup(var.monitoring, "prometheus", {}), "node_exporter", {}), "image", "${data.aws_caller_identity.current.id}.dkr.ecr.eu-west-3.amazonaws.com/node-exporter")
  prometheus_node_exporter_tag   = lookup(lookup(lookup(var.monitoring, "prometheus", {}), "node_exporter", {}), "tag", "latest")
  prometheus_node_selector       = lookup(lookup(var.monitoring, "prometheus", {}), "node_selector", {})

  # Prometheus adapter
  prometheus_adapter_image              = lookup(lookup(var.monitoring, "prometheus_adapter", {}), "image", "${data.aws_caller_identity.current.id}.dkr.ecr.eu-west-3.amazonaws.com/prometheus-adapter")
  prometheus_adapter_tag                = lookup(lookup(var.monitoring, "prometheus_adapter", {}), "tag", "v0.9.1")
  prometheus_adapter_image_pull_secrets = lookup(lookup(var.monitoring, "prometheus_adapter", {}), "image_pull_secrets", "")
  prometheus_adapter_service_type       = lookup(lookup(var.monitoring, "prometheus_adapter", {}), "service_type", "ClusterIP")
  prometheus_adapter_node_selector      = lookup(lookup(var.monitoring, "prometheus_adapter", {}), "node_selector", {})

  # Metrics exporter
  metrics_exporter_image              = lookup(lookup(var.monitoring, "metrics_exporter", {}), "image", "${data.aws_caller_identity.current.id}.dkr.ecr.eu-west-3.amazonaws.com/metrics-exporter")
  metrics_exporter_tag                = lookup(lookup(var.monitoring, "metrics_exporter", {}), "tag", "0.4.1-newtaskcreationapi.56.a51b258")
  metrics_exporter_image_pull_secrets = lookup(lookup(var.monitoring, "metrics_exporter", {}), "image_pull_secrets", "")
  metrics_exporter_service_type       = lookup(lookup(var.monitoring, "metrics_exporter", {}), "service_type", "ClusterIP")
  metrics_exporter_node_selector      = lookup(lookup(var.monitoring, "metrics_exporter", {}), "node_selector", {})

  # CloudWatch
  cloudwatch_enabled           = tobool(lookup(lookup(var.monitoring, "cloudwatch", {}), "enabled", false))
  cloudwatch_kms_key_id        = lookup(lookup(var.monitoring, "cloudwatch", {}), "kms_key_id", "")
  cloudwatch_retention_in_days = tonumber(lookup(lookup(var.monitoring, "cloudwatch", {}), "retention_in_days", 30))

  # Fluent-bit
  fluent_bit_image              = lookup(lookup(var.monitoring, "fluent_bit", {}), "image", "${data.aws_caller_identity.current.id}.dkr.ecr.eu-west-3.amazonaws.com/fluent-bit")
  fluent_bit_tag                = lookup(lookup(var.monitoring, "fluent_bit", {}), "tag", "1.3.11")
  fluent_bit_image_pull_secrets = lookup(lookup(var.monitoring, "fluent_bit", {}), "image_pull_secrets", "")
  fluent_bit_is_daemonset       = tobool(lookup(lookup(var.monitoring, "fluent_bit", {}), "is_daemonset", false))
  fluent_bit_http_port          = tonumber(lookup(lookup(var.monitoring, "fluent_bit", {}), "http_port", 0))
  fluent_bit_read_from_head     = tobool(lookup(lookup(var.monitoring, "fluent_bit", {}), "read_from_head", true))
  fluent_bit_node_selector      = lookup(lookup(var.monitoring, "fluent_bit", {}), "node_selector", {})
}
