module "application_logs" {
  source            = "../../aws/cloudwatch-log-group"
  name              = "/aws/containerinsights/${var.cluster_info.cluster_name}/application"
  kms_key_id        = var.cloudwatch_log_group.kms_key_id
  retention_in_days = var.cloudwatch_log_group.retention_in_days
  tags              = var.cloudwatch_log_group.tags
}

module "dataplane_logs" {
  source            = "../../aws/cloudwatch-log-group"
  name              = "/aws/containerinsights/${var.cluster_info.cluster_name}/dataplane"
  kms_key_id        = var.cloudwatch_log_group.kms_key_id
  retention_in_days = var.cloudwatch_log_group.retention_in_days
  tags              = var.cloudwatch_log_group.tags
}

module "host_logs" {
  source            = "../../aws/cloudwatch-log-group"
  name              = "/aws/containerinsights/${var.cluster_info.cluster_name}/host"
  kms_key_id        = var.cloudwatch_log_group.kms_key_id
  retention_in_days = var.cloudwatch_log_group.retention_in_days
  tags              = var.cloudwatch_log_group.tags
}