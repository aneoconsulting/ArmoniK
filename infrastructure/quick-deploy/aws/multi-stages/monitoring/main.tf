# AWS KMS
module "kms" {
  count  = local.cloudwatch_enabled && !can(coalesce(local.cloudwatch_kms_key_id)) ? 1 : 0
  source = "../generated/infra-modules/security/aws/kms"
  name   = local.kms_name
  tags   = local.tags

  key_asymmetric_sign_verify_users = [
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling",
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
  ]
  key_service_users = [
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling",
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
  ]
  key_statements = [
    {
      sid = "CloudWatchLogs"
      actions = [
        "kms:Encrypt*",
        "kms:Decrypt*",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:Describe*"
      ]
      resources = ["*"]

      principals = [
        {
          type        = "Service"
          identifiers = ["logs.${var.region}.amazonaws.com"]
        }
      ]

      conditions = [
        {
          test     = "ArnLike"
          variable = "kms:EncryptionContext:aws:logs:arn"
          values = [
            "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:*",
          ]
        }
      ]
    }
  ]
}

# Seq
module "seq" {
  count         = (local.seq_enabled ? 1 : 0)
  source        = "../generated/infra-modules/monitoring/onpremise/seq"
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
  authentication    = var.authentication
  system_ram_target = local.seq_system_ram_target
  retention_in_days = local.retention_in_days
}

# node exporter
module "node_exporter" {
  count         = (local.node_exporter_enabled ? 1 : 0)
  source        = "../generated/infra-modules/monitoring/onpremise/exporters/node-exporter"
  namespace     = var.namespace
  node_selector = local.node_exporter_node_selector
  docker_image = {
    image              = local.node_exporter_image
    tag                = local.node_exporter_tag
    image_pull_secrets = local.node_exporter_image_pull_secrets
  }
}

# Metrics exporter
module "metrics_exporter" {
  source        = "../generated/infra-modules/monitoring/onpremise/exporters/metrics-exporter"
  namespace     = var.namespace
  service_type  = local.metrics_exporter_service_type
  node_selector = local.metrics_exporter_node_selector
  docker_image = {
    image              = local.metrics_exporter_image
    tag                = local.metrics_exporter_tag
    image_pull_secrets = local.metrics_exporter_image_pull_secrets
  }
  extra_conf = local.metrics_exporter_extra_conf
}

# Partition metrics exporter
#module "partition_metrics_exporter" {
#  source               = "../generated/infra-modules/monitoring/onpremise/exporters/partition-metrics-exporter"
#  namespace            = var.namespace
#  service_type         = local.partition_metrics_exporter_service_type
#  node_selector        = local.partition_metrics_exporter_node_selector
#  storage_endpoint_url = var.storage_endpoint_url
#  metrics_exporter_url = "${module.metrics_exporter.host}:${module.metrics_exporter.port}"
#  docker_image = {
#    image              = local.partition_metrics_exporter_image
#    tag                = local.partition_metrics_exporter_tag
#    image_pull_secrets = local.partition_metrics_exporter_image_pull_secrets
#  }
#  extra_conf  = local.partition_metrics_exporter_extra_conf
#  depends_on  = [module.metrics_exporter]
#}

# Prometheus
module "prometheus" {
  source               = "../generated/infra-modules/monitoring/onpremise/prometheus"
  namespace            = var.namespace
  service_type         = local.prometheus_service_type
  node_selector        = local.prometheus_node_selector
  metrics_exporter_url = "${module.metrics_exporter.host}:${module.metrics_exporter.port}"
  #"${module.partition_metrics_exporter.host}:${module.partition_metrics_exporter.port}"
  docker_image = {
    image              = local.prometheus_image
    tag                = local.prometheus_tag
    image_pull_secrets = local.prometheus_image_pull_secrets
  }
  depends_on = [
    module.metrics_exporter,
    #module.partition_metrics_exporter
  ]
}

# Grafana
module "grafana" {
  count          = (local.grafana_enabled ? 1 : 0)
  source         = "../generated/infra-modules/monitoring/onpremise/grafana"
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
  authentication = var.authentication
  depends_on     = [module.prometheus]
}

# CloudWatch
module "cloudwatch" {
  count             = (local.cloudwatch_enabled ? 1 : 0)
  source            = "../generated/infra-modules/monitoring/aws/cloudwatch-log-group"
  name              = local.cloudwatch_log_group_name
  kms_key_id        = try(coalesce(local.cloudwatch_kms_key_id), module.kms[0].key_arn)
  retention_in_days = local.cloudwatch_retention_in_days
  tags              = local.tags
}

# Fluent-bit
module "fluent_bit" {
  source        = "../generated/infra-modules/monitoring/onpremise/fluent-bit"
  namespace     = var.namespace
  node_selector = local.fluent_bit_node_selector
  fluent_bit = {
    container_name                     = "fluent-bit"
    image                              = local.fluent_bit_image
    tag                                = local.fluent_bit_tag
    image_pull_secrets                 = local.fluent_bit_image_pull_secrets
    is_daemonset                       = local.fluent_bit_is_daemonset
    parser                             = local.fluent_bit_parser
    http_server                        = (local.fluent_bit_http_port == 0 ? "Off" : "On")
    http_port                          = (local.fluent_bit_http_port == 0 ? "" : tostring(local.fluent_bit_http_port))
    read_from_head                     = (local.fluent_bit_read_from_head ? "On" : "Off")
    read_from_tail                     = (local.fluent_bit_read_from_head ? "Off" : "On")
    fluent_bit_state_hostpath          = var.monitoring.fluent_bit.fluent_bit_state_hostpath
    var_lib_docker_containers_hostpath = var.monitoring.fluent_bit.var_lib_docker_containers_hostpath
    run_log_journal_hostpath           = var.monitoring.fluent_bit.run_log_journal_hostpath
  }
  seq = (local.seq_enabled ? {
    host    = module.seq.0.host
    port    = module.seq.0.port
    enabled = true
  } : {})
  cloudwatch = (local.cloudwatch_enabled ? {
    name    = module.cloudwatch.0.name
    region  = var.region
    enabled = true
  } : {})
  s3 = (local.s3_enabled ? {
    name    = local.s3_name
    region  = local.s3_region
    prefix  = local.suffix
    enabled = true
  } : {})
}
