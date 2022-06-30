# Slow log and engine log not yet available in Terraform
module "slow_log" {
  source            = "../cloudwatch-log-group"
  name              = local.slow_log_name
  kms_key_id        = var.elasticache.encryption_keys.log_kms_key_id
  retention_in_days = var.elasticache.log_retention_in_days
  tags              = local.tags
}

module "engine_log" {
  source            = "../cloudwatch-log-group"
  name              = local.engine_log_name
  kms_key_id        = var.elasticache.encryption_keys.log_kms_key_id
  retention_in_days = var.elasticache.log_retention_in_days
  tags              = local.tags
}