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
    prometheus    = {
      image = var.monitoring.prometheus.image
      tag   = var.monitoring.prometheus.tag
    }
    node_exporter = {
      image = var.monitoring.prometheus.node_exporter.image
      tag   = var.monitoring.prometheus.node_exporter.tag
    }
  }
  working_dir   = "${path.root}/../../.."
}

/*# KMS key for cloudwatch
module "kms" {
  count  = (var.monitoring.cloudwatch.kms_key_id == "" ? 1 : 0)
  source = "../../../modules/aws/kms"
  name   = "armonik-kms-application-logs-${local.suffix}-${local.random_string}"
  tags   = local.tags
}

# Fluent-bit for CloudWatch
module "fluent_bit_cloudwatch" {
  count                = (var.monitoring.cloudwatch.use ? 1 : 0)
  source               = "../../../modules/monitoring/fluent-bit-cloudwatch"
  namespace            = var.namespace
  node_selector        = var.node_selector
  ci_version           = var.monitoring.cloudwatch.ci_version
  cluster_info         = {
    cluster_name              = local.cluster_name
    log_region                = var.region
    fluent_bit_http_port      = var.monitoring.cloudwatch.fluent_bit_http_port
    fluent_bit_read_from_head = var.monitoring.cloudwatch.fluent_bit_read_from_head
  }
  fluent_bit           = {
    image = var.monitoring.cloudwatch.fluent_bit.image
    tag   = var.monitoring.cloudwatch.fluent_bit.tag
  }
  cloudwatch_log_group = {
    kms_key_id        = (var.monitoring.cloudwatch.kms_key_id != "" ? var.monitoring.cloudwatch.kms_key_id : module.kms.0.selected.arn)
    retention_in_days = var.monitoring.cloudwatch.retention_in_days
    tags              = local.tags
  }
}*/