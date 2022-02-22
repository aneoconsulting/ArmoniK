data "aws_caller_identity" "current" {}

resource "random_string" "random_resources" {
  length  = 5
  special = false
  upper   = false
  number  = true
}

locals {
  random_string = random_string.random_resources.result
  suffix        = var.suffix != null && var.suffix != "" ? var.suffix : local.random_string
  cluster_name  = lookup(var.eks, "name", "")
  tags          = merge(var.tags, {
    application        = "ArmoniK"
    deployment_version = local.suffix
    created_by         = data.aws_caller_identity.current.arn
    date               = formatdate("EEE-DD-MMM-YY-hh:mm:ss:ZZZ", tostring(timestamp()))
    resource           = "monitoring"
  })

  # Seq
  seq_use          = tobool(lookup(lookup(var.monitoring, "seq", {}), "use", false))
  seq_image        = lookup(lookup(var.monitoring, "seq", {}), "image", "${data.aws_caller_identity.current.id}.dkr.ecr.eu-west-3.amazonaws.com/seq")
  seq_tag          = lookup(lookup(var.monitoring, "seq", {}), "tag", "2021.4")
  seq_service_type = lookup(lookup(var.monitoring, "seq", {}), "service_type", "LoadBalancer")

  # Grafana
  grafana_use          = tobool(lookup(lookup(var.monitoring, "grafana", {}), "use", false))
  grafana_image        = lookup(lookup(var.monitoring, "grafana", {}), "image", "${data.aws_caller_identity.current.id}.dkr.ecr.eu-west-3.amazonaws.com/grafana")
  grafana_tag          = lookup(lookup(var.monitoring, "grafana", {}), "tag", "latest")
  grafana_service_type = lookup(lookup(var.monitoring, "grafana", {}), "service_type", "LoadBalancer")

  # Prometheus
  prometheus_use                 = tobool(lookup(lookup(var.monitoring, "prometheus", {}), "use", false))
  prometheus_image               = lookup(lookup(var.monitoring, "prometheus", {}), "image", "${data.aws_caller_identity.current.id}.dkr.ecr.eu-west-3.amazonaws.com/prometheus")
  prometheus_tag                 = lookup(lookup(var.monitoring, "prometheus", {}), "tag", "latest")
  prometheus_service_type        = lookup(lookup(var.monitoring, "prometheus", {}), "service_type", "ClusterIP")
  prometheus_node_exporter_image = lookup(lookup(lookup(var.monitoring, "prometheus", {}), "node_exporter", {}), "image", "${data.aws_caller_identity.current.id}.dkr.ecr.eu-west-3.amazonaws.com/node-exporter")
  prometheus_node_exporter_tag   = lookup(lookup(lookup(var.monitoring, "prometheus", {}), "node_exporter", {}), "tag", "latest")

  # CloudWatch
  cloudwatch_use               = tobool(lookup(lookup(var.monitoring, "cloudwatch", {}), "use", false))
  cloudwatch_ci_version        = lookup(lookup(var.monitoring, "cloudwatch", {}), "ci_version", "k8s/1.3.8")
  cloudwatch_kms_key_id        = lookup(lookup(var.monitoring, "cloudwatch", {}), "kms_key_id", "")
  cloudwatch_retention_in_days = tonumber(lookup(lookup(var.monitoring, "cloudwatch", {}), "retention_in_days", 30))

  # Fluent-bit
  fluent_bit_image          = lookup(lookup(var.monitoring, "fluent_bit", {}), "image", "${data.aws_caller_identity.current.id}.dkr.ecr.eu-west-3.amazonaws.com/fluent-bit")
  fluent_bit_tag            = lookup(lookup(var.monitoring, "fluent_bit", {}), "tag", "1.3.11")
  fluent_bit_is_daemonset   = tobool(lookup(lookup(var.monitoring, "fluent_bit", {}), "is_daemonset", false))
  fluent_bit_http_port      = tonumber(lookup(lookup(var.monitoring, "fluent_bit", {}), "http_port", 0))
  fluent_bit_read_from_head = tobool(lookup(lookup(var.monitoring, "fluent_bit", {}), "read_from_head", true))
}
